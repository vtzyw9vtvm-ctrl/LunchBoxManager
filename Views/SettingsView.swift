import SwiftUI

struct SettingsView: View {

    @State private var showRestoreConfirmation = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    @State private var menuManager = MenuViewModel()

    private let firebaseMenuService = FirebaseMenuService()

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text("Settings")
                    .font(.largeTitle.bold())

                Text("Manage LunchBoxManager settings and data.")
                    .foregroundStyle(.secondary)

                Divider()

                // MARK: - Menu Data

                VStack(alignment: .leading, spacing: 16) {

                    Label(
                        "Menu Data",
                        systemImage: "fork.knife"
                    )
                    .font(.title2.bold())

                    Text(
                        "Manage the menu stored on this Mac and the published menu stored in Firebase."
                    )
                    .foregroundStyle(.secondary)

                    Divider()

                    HStack {

                        VStack(alignment: .leading, spacing: 5) {

                            Text("Restore Menu from Firebase")
                                .font(.headline)

                            Text(
                                "Replace the menu on this Mac with the currently published Firebase menu."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            showRestoreConfirmation = true
                        } label: {

                            if isRestoring {

                                ProgressView()
                                    .controlSize(.small)

                            } else {

                                Label(
                                    "Restore Menu",
                                    systemImage: "icloud.and.arrow.down"
                                )
                            }
                        }
                        .disabled(isRestoring)
                    }

                    if let restoreMessage {

                        Divider()

                        Text(restoreMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )

                Spacer()
            }
            .padding(30)
            .frame(maxWidth: 900, alignment: .leading)
        }

        .confirmationDialog(
            "Restore Menu from Firebase?",
            isPresented: $showRestoreConfirmation,
            titleVisibility: .visible
        ) {

            Button(
                "Restore Menu",
                role: .destructive
            ) {

                Task {

                    isRestoring = true
                    restoreMessage = nil

                    do {

                        let restoredCategories =
                            try await firebaseMenuService.loadMenu()

                        guard !restoredCategories.isEmpty else {

                            restoreMessage =
                                "No menu found in Firebase."

                            isRestoring = false
                            return
                        }

                        menuManager.restoreMenu(restoredCategories)

                        restoreMessage =
                            "Menu restored from Firebase successfully."

                    } catch {

                        restoreMessage =
                            "Restore failed: \(error.localizedDescription)"
                    }

                    isRestoring = false
                }
            }

            Button("Cancel", role: .cancel) {}

        } message: {

            Text(
                "This will replace the menu currently stored on this Mac with the menu saved in Firebase. This cannot be undone."
            )
        }
    }
}

#Preview {
    SettingsView()
}
