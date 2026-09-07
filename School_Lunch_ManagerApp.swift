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

    @Published private(set) var isSignedIn: Bool

    private var authListener:
        AuthStateDidChangeListenerHandle?

    init() {
        isSignedIn = Auth.auth().currentUser != nil

        authListener = Auth.auth()
            .addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.isSignedIn = user != nil
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
