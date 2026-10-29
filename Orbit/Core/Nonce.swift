import CryptoKit
import Foundation
import Security

/// Binds a provider's token to one sign-in attempt. The provider gets `hashed`; the API gets `raw` and checks
/// SHA-256(raw) against the token's `nonce` claim, so a token minted for another attempt can't be replayed.
struct Nonce {
    let raw: String

    init(raw: String = Nonce.random()) { self.raw = raw }

    var hashed: String { Nonce.sha256Hex(raw) }

    static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func random(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        precondition(SecRandomCopyBytes(kSecRandomDefault, length, &bytes) == errSecSuccess, "no randomness")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }
}
