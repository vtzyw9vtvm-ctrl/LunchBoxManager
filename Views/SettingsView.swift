import SwiftUI

struct SettingsView: View {

    // MARK: - Menu Restore

    @State private var showRestoreConfirmation = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    @State private var menuManager = MenuViewModel()

    // MARK: - Modifier Restore

    @State private var showModifierRestoreConfirmation = false
    @State private var isRestoringModifiers = false
    @State private var modifierRestoreMessage: String?

    @State private var modifierManager = ModifierManager()

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
                        .fill(
                            Color(
                                nsColor: .controlBackgroundColor
                            )
                        )
                )

                // MARK: - Modifier Data

                VStack(alignment: .leading, spacing: 16) {

                    Label(
                        "Modifier Data",
                        systemImage: "slider.horizontal.3"
                    )
                    .font(.title2.bold())

                    Text(
                        "Recover modifier groups from the currently published Firebase menu."
                    )
                    .foregroundStyle(.secondary)

                    Divider()

                    HStack {

                        VStack(alignment: .leading, spacing: 5) {

                            Text(
                                "Restore Modifier Groups from Firebase"
                            )
                            .font(.headline)

                            Text(
                                "Replace the modifier groups stored on this Mac with the groups found in the published Firebase menu."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            showModifierRestoreConfirmation = true
                        } label: {

                            if isRestoringModifiers {

                                ProgressView()
                                    .controlSize(.small)

                            } else {

                                Label(
                                    "Restore Modifiers",
                                    systemImage: "icloud.and.arrow.down"
                                )
                            }
                        }
                        .disabled(isRestoringModifiers)
                    }

                    if let modifierRestoreMessage {

                        Divider()

                        Text(modifierRestoreMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            Color(
                                nsColor: .controlBackgroundColor
                            )
                        )
                )

                Spacer()
            }
            .padding(30)
            .frame(maxWidth: 900, alignment: .leading)
        }

        // MARK: - Restore Menu Confirmation

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

                        menuManager.restoreMenu(
                            restoredCategories
                        )

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

        // MARK: - Restore Modifier Confirmation

        .confirmationDialog(
            "Restore Modifier Groups from Firebase?",
            isPresented: $showModifierRestoreConfirmation,
            titleVisibility: .visible
        ) {

            Button(
                "Restore Modifier Groups",
                role: .destructive
            ) {

                Task {

                    isRestoringModifiers = true
                    modifierRestoreMessage = nil

                    do {

                        let restoredGroups =
                            try await firebaseMenuService
                                .loadModifierGroups()

                        guard !restoredGroups.isEmpty else {

                            modifierRestoreMessage =
                                "No modifier groups found in Firebase."

                            isRestoringModifiers = false
                            return
                        }

                        modifierManager.groups =
                            restoredGroups

                        modifierManager.save()

                        modifierRestoreMessage =
                            "Modifier groups restored from Firebase successfully."

                    } catch {

                        modifierRestoreMessage =
                            "Restore failed: \(error.localizedDescription)"
                    }

                    isRestoringModifiers = false
                }
            }

            Button("Cancel", role: .cancel) {}

        } message: {

            Text(
                "This will replace the modifier groups currently stored on this Mac with the modifier groups found in the published Firebase menu."
            )
        }
    }
}

#Preview {
    SettingsView()
}
