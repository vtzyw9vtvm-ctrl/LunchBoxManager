import SwiftUI
import FirebaseCore
import FirebaseAuth

struct ManagerSignInView: View {
    @State private var email = ""
    @State private var password = ""

    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("LunchBoxManager")
                .font(.system(size: 32, weight: .bold))

            Text("Manager Sign In")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 320)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 320)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .frame(width: 320)
                }

                Button {
                    signIn()
                } label: {
                    if isSigningIn {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Sign In")
                            .frame(width: 120)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    email.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty ||
                    password.isEmpty ||
                    isSigningIn
                )
            }

            Spacer()
        }
        .frame(
            minWidth: 500,
            minHeight: 400
        )
    }

    private func signIn() {
        errorMessage = nil
        isSigningIn = true

        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // First sign into the normal LunchBox Firebase project.
        Auth.auth().signIn(
            withEmail: cleanEmail,
            password: password
        ) { _, error in

            if let error {
                DispatchQueue.main.async {
                    isSigningIn = false
                    errorMessage = error.localizedDescription
                }
                return
            }

            // Now connect to the Espresso Cafe Firebase project.
            let espressoApp: FirebaseApp

            if let existingApp = FirebaseApp.app(
                name: "EspressoCafe"
            ) {
                espressoApp = existingApp
            } else {
                guard let plistPath = Bundle.main.path(
                    forResource: "GoogleService-Info-Espresso",
                    ofType: "plist"
                ),
                let options = FirebaseOptions(
                    contentsOfFile: plistPath
                ) else {
                    DispatchQueue.main.async {
                        isSigningIn = false
                        errorMessage =
                            "Could not load the Espresso Cafe Firebase configuration."
                    }
                    return
                }

                FirebaseApp.configure(
                    name: "EspressoCafe",
                    options: options
                )

                guard let configuredApp = FirebaseApp.app(
                    name: "EspressoCafe"
                ) else {
                    DispatchQueue.main.async {
                        isSigningIn = false
                        errorMessage =
                            "Could not connect to Espresso Cafe Firebase."
                    }
                    return
                }

                espressoApp = configuredApp
            }

            // Sign into Espresso Firebase using the same credentials.
            let espressoAuth = Auth.auth(app: espressoApp)

            espressoAuth.signIn(
                withEmail: cleanEmail,
                password: password
            ) { result, espressoError in

                DispatchQueue.main.async {
                    isSigningIn = false

                    if let espressoError {
                        errorMessage =
                            "Espresso Cafe sign in failed: " +
                            espressoError.localizedDescription
                        return
                    }

                    guard let espressoUser = result?.user else {
                        errorMessage =
                            "Espresso Cafe sign in failed."
                        return
                    }

                    // Force a fresh token so the new manager claim is included.
                    espressoUser.getIDTokenResult(
                        forcingRefresh: true
                    ) { tokenResult, tokenError in

                        DispatchQueue.main.async {
                            if let tokenError {
                                errorMessage =
                                    tokenError.localizedDescription
                                return
                            }

                            let isEspressoManager =
                                tokenResult?.claims["manager"]
                                    as? Bool ?? false

                            if isEspressoManager {
                                print(
                                    "☕️ ESPRESSO MANAGER SIGN IN SUCCESS"
                                )
                            } else {
                                errorMessage =
                                    "This account does not have Espresso Cafe Manager access."
                            }
                        }
                    }
                }
            }
        }
    }
}
