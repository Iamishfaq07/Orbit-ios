import XCTest
@testable import Orbit

final class DecodingTests: XCTestCase {
    func testTrackedJobDecodesServerShape() throws {
        let json = """
        {"id":"a","listing_id":"l","source":"x","company":"Acme","title":"Engineer","location":"Pune","url":"u",
         "apply_url":"u","posted_at":null,"status":"interviewing","notes":"","applied_at":"2026-10-01T10:00:00Z",
         "next_at":"2026-10-30T09:30:00.123456+00:00","status_at":"2026-10-20T10:00:00","resume_id":null,
         "document_id":null,"live":true,"created_at":"2026-10-01T10:00:00Z","updated_at":"2026-10-01T10:00:00Z"}
        """.data(using: .utf8)!
        let job = try APIClient.decoder.decode(TrackedJob.self, from: json)
        XCTAssertEqual(job.status, .interviewing)
        XCTAssertEqual(job.status.routeIndex, 2)
        XCTAssertNotNil(job.nextAt)
    }

    func testClosedStatusesHaveNoRouteStop() {
        XCTAssertNil(JobStatus.rejected.routeIndex)
        XCTAssertNil(JobStatus.withdrawn.routeIndex)
    }

    func testErrorMessageNeverLeaksServerInternals() {
        XCTAssertEqual(APIClient.message(from: Data("<html>".utf8), status: 500), "Something went wrong. Please try again.")
        XCTAssertEqual(APIClient.message(from: Data(#"{"detail":"Invalid email or password."}"#.utf8), status: 401), "Invalid email or password.")
    }
}

final class FeedDecodingTests: XCTestCase {
    func testFeedPageDecodesAndIgnoresUnknownFields() throws {
        let json = """
        {"items":[{"id":"1","source":"gh","source_label":"Greenhouse","direct":true,"attribution":null,"company":"Acme",
        "title":"iOS Engineer","locations":["Pune"],"place":"Pune · Hybrid","workplace":"hybrid","employment_type":null,
        "level":null,"experience":"3-5 years","posted_at":"2026-10-25T08:00:00Z","url":"https://a.test/j",
        "apply_url":"https://a.test/apply","snippet":"Build things","salary":null,"first_seen_at":"2026-10-25T08:00:00Z",
        "match":{"score":82,"matched":["Swift"],"missing":["Kotlin"]},"tracked":{"id":"t1","status":"saved"}}],
        "total":1,"page":1,"page_size":20,"has_more":false,"refreshing":false,"has_profile":true}
        """.data(using: .utf8)!
        let feed = try APIClient.decoder.decode(FeedPage.self, from: json)
        XCTAssertEqual(feed.items.first?.match?.score, 82)
        XCTAssertEqual(feed.items.first?.tracked?.status, .saved)
        XCTAssertEqual(feed.items.first?.applyLink?.absoluteString, "https://a.test/apply")
    }

    func testApplyLinkRejectsNonHTTP() throws {
        var job = try APIClient.decoder.decode(Job.self, from: Data("""
        {"id":"1","source_label":"x","direct":false,"company":"A","title":"T","place":"P","experience":null,
        "posted_at":"2026-10-25T08:00:00Z","url":"javascript:alert(1)","apply_url":"","snippet":"","salary":null,"match":null,"tracked":null}
        """.utf8))
        XCTAssertNil(job.applyLink)
        job.tracked = TrackedRef(id: "t", status: .applied)
        XCTAssertEqual(job.tracked?.status, .applied)
    }
}

final class NonceTests: XCTestCase {
    func testHashMatchesSHA256Hex() {
        // The API compares the token's nonce claim to SHA-256(raw) as lowercase hex.
        XCTAssertEqual(Nonce.sha256Hex("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testRandomNoncesDifferAndAreLongEnoughForTheAPI() {
        let a = Nonce(), b = Nonce()
        XCTAssertNotEqual(a.raw, b.raw)
        XCTAssertGreaterThanOrEqual(a.raw.count, 16)   // the API requires 16...256
    }

    func testAuthConfigDecodes() throws {
        let cfg = try APIClient.decoder.decode(AuthConfig.self, from: Data(#"{"captcha":null,"email_verification":"off","google":true,"apple":false}"#.utf8))
        XCTAssertEqual(cfg, AuthConfig(google: true, apple: false))
    }
}

final class TrackPatchTests: XCTestCase {
    func testOnlySetFieldsAreSent() throws {
        let data = try APIClient.encoder.encode(TrackPatch(status: .applied))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["status"] as? String, "applied")
        XCTAssertEqual(Set(json.keys), ["status"])   // notes, next_at, clear_next left alone
    }

    func testClearingTheNextDateUsesTheServersFlag() throws {
        let data = try APIClient.encoder.encode(TrackPatch(clearNext: true))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["clear_next"] as? Bool, true)
    }
}

final class RemindersTests: XCTestCase {
    private func job(_ id: String, status: JobStatus, next: Date?) throws -> TrackedJob {
        let iso = ISO8601DateFormatter()
        let nextJSON = next.map { "\"\(iso.string(from: $0))\"" } ?? "null"
        let json = """
        {"id":"\(id)","listing_id":"l","company":"Acme","title":"Engineer","location":"","url":"","status":"\(status.rawValue)",
         "notes":"","applied_at":null,"next_at":\(nextJSON),"status_at":"2026-10-01T00:00:00Z","live":true}
        """
        return try APIClient.decoder.decode(TrackedJob.self, from: Data(json.utf8))
    }

    func testRemindsAnHourBeforeAndSkipsPastClosedAndUndated() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let jobs = [
            try job("soon", status: .interviewing, next: now.addingTimeInterval(3 * 3600)),
            try job("inside-lead", status: .applied, next: now.addingTimeInterval(1800)),
            try job("past", status: .applied, next: now.addingTimeInterval(-3600)),
            try job("closed", status: .rejected, next: now.addingTimeInterval(5 * 3600)),
            try job("undated", status: .saved, next: nil),
        ]
        let plan = Reminders.plan(jobs: jobs, now: now)
        XCTAssertEqual(plan.map(\.id), ["orbit.stop.soon"])
        XCTAssertEqual(plan.first?.fireAt, now.addingTimeInterval(2 * 3600))
    }

    func testKeepsTheEarliestWithinTheSystemLimit() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let jobs = try (0..<70).map { try job("j\($0)", status: .applied, next: now.addingTimeInterval(Double(70 - $0 + 2) * 3600)) }
        let plan = Reminders.plan(jobs: jobs, now: now)
        XCTAssertEqual(plan.count, Reminders.limit)
        XCTAssertEqual(plan.first?.id, "orbit.stop.j69")   // soonest first
    }
}
