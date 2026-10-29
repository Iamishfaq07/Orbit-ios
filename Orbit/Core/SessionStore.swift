import Observation

@MainActor @Observable
final class SessionStore {
    enum State: Equatable { case loading, signedOut, signedIn }

    private(set) var state: State = .loading
    private(set) var user: User?
    private let auth = AuthService()

    /// On launch: use the keychain token if the server still accepts it.
    func restore() async {
        guard let token = KeychainStore.load() else { state = .signedOut; return }
        await APIClient.shared.setToken(token)
        do {
            user = try await auth.me()
            state = .signedIn
        } catch let e as APIError where e.isUnauthorized {
            await clear()
        } catch {
            // Offline or server trouble: keep the session, show the app; screens handle their own errors.
            state = .signedIn
        }
    }

    func complete(_ response: AuthResponse) async {
        guard let token = response.accessToken else { return }
        KeychainStore.save(token)
        await APIClient.shared.setToken(token)
        user = response.user
        state = .signedIn
    }

    func signOut() async {
        await auth.logout()
        await clear()
    }

    private func clear() async {
        KeychainStore.delete()
        await Reminders.clear()
        await APIClient.shared.setToken(nil)
        user = nil
        state = .signedOut
    }
}
