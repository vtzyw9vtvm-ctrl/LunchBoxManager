import SwiftUI
import FirebaseCore
import FirebaseAuth
import Combine

@main
struct School_Lunch_ManagerApp: App {

    @StateObject private var authManager: ManagerAuthManager

    init() {
        FirebaseApp.configure()

        _authManager = StateObject(
            wrappedValue: ManagerAuthManager()
        )

        Task {
            await FirestoreService().testConnection()
        }
    }

    var body: some Scene {
        WindowGroup("LunchBoxManager") {
            Group {
                if authManager.isSignedIn {
                    SidebarView()
                } else {
                    ManagerSignInView()
                }
            }
            .environmentObject(authManager)
        }
        .windowResizability(.automatic)
        .defaultSize(
            width: 1400,
            height: 900
        )
    }
}


// MARK: - Manager Authentication

final class ManagerAuthManager: ObservableObject {

    @Published private(set) var isSignedIn = false
    @Published private(set) var isCheckingAccess = true
    @Published private(set) var accessError: String?

    private var authListener:
        AuthStateDidChangeListenerHandle?

    init() {

        authListener = Auth.auth()
            .addStateDidChangeListener { [weak self] _, user in

                guard let self else { return }

                guard let user else {
                    DispatchQueue.main.async {
                        self.isSignedIn = false
                        self.isCheckingAccess = false
                        self.accessError = nil
                    }
                    return
                }

                self.checkManagerAccess(for: user)
            }
    }

    private func checkManagerAccess(for user: User) {

        DispatchQueue.main.async {
            self.isCheckingAccess = true
            self.accessError = nil
        }

        user.getIDTokenResult(forcingRefresh: true) { [weak self] result, error in

            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.isSignedIn = false
                    self.isCheckingAccess = false
                    self.accessError = error.localizedDescription
                }
                return
            }

            let isManager =
                result?.claims["manager"] as? Bool ?? false

            if isManager {

                DispatchQueue.main.async {
                    self.isSignedIn = true
                    self.isCheckingAccess = false
                    self.accessError = nil
                }

            } else {

                // Signed in, but this Firebase account
                // does not have Manager permission.
                do {
                    try Auth.auth().signOut()
                } catch {
                    print(
                        "Failed to sign out unauthorised user:",
                        error
                    )
                }

                DispatchQueue.main.async {
                    self.isSignedIn = false
                    self.isCheckingAccess = false
                    self.accessError =
                        "This account does not have Manager access."
                }
            }
        }
    }

    deinit {

        if let authListener {
            Auth.auth().removeStateDidChangeListener(
                authListener
            )
        }
    }
}
