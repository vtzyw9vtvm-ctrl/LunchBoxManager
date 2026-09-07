import SwiftUI
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

        Auth.auth().signIn(
            withEmail: cleanEmail,
            password: password
        ) { _, error in
            DispatchQueue.main.async {
                isSigningIn = false

                if let error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
