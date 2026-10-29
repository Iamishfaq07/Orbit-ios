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
