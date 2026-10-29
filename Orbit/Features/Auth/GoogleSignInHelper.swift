@preconcurrency import GoogleSignIn
import UIKit

/// Google's sign-in sheet. Needs `GOOGLE_IOS_CLIENT_ID` (project.yml) from the iOS OAuth client in Google Cloud;
/// without it the button is not shown.
@MainActor
enum GoogleSignInHelper {
    static var isConfigured: Bool {
        let id = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? ""
        return !id.isEmpty
    }

    /// Returns the id token to send to the API. Throws `GIDSignInError.canceled` when the user backs out.
    static func idToken(nonce: Nonce) async throws -> String {
        guard let presenter = topViewController() else { throw APIError(status: 0, message: "Couldn't open Google sign-in.") }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter, hint: nil,
                                                               additionalScopes: nil, nonce: nonce.hashed)
        guard let token = result.user.idToken?.tokenString else {
            throw APIError(status: 0, message: "Google didn't return a sign-in token.")
        }
        return token
    }

    static func isCancel(_ error: Error) -> Bool {
        (error as NSError).domain == kGIDSignInErrorDomain && (error as NSError).code == GIDSignInError.canceled.rawValue
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.keyWindow?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}
