import SwiftUI
import FirebaseAuth

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
    
    // MARK: - Account
    
    @State private var showChangePassword = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordMessage: String?
    @State private var isChangingPassword = false
    
    private let firebaseMenuService = FirebaseMenuService()
    
    // MARK: - Cafe Online Ordering
    
    @State private var cafeOrderingSettings =
    CafeOrderingSettings.defaultSettings
    
    @State private var isLoadingCafeOrderingSettings = false
    @State private var isSavingCafeOrderingSettings = false
    @State private var cafeOrderingSettingsMessage: String?
    @State private var isVerifyingCafeAddress = false
    
    private let cafeOrderingSettingsService =
    CafeOrderingSettingsService.shared
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            PageBannerView(
                title: "Settings",
                subtitle: "Manage LunchBox Manager settings and data",
                systemImage: "gearshape.fill",
                color: .lunchBoxBlue
            )
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Menu Data
                    
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
                    
                    // MARK: - Cafe Online Ordering
                    
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Label(
                            "Cafe Online Ordering",
                            systemImage: "cup.and.saucer.fill"
                        )
                        .font(.title2.bold())
                        
                        Text(
                            "Control when customers can place Espresso Cafe orders."
                        )
                        .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        Toggle(
                            "Online Ordering",
                            isOn: $cafeOrderingSettings.onlineOrderingEnabled
                        )
                        
                        Text(
                            "Turn this off to temporarily stop all new online orders."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        Toggle(
                            "Pickup",
                            isOn: $cafeOrderingSettings.pickupEnabled
                        )
                        
                        Toggle(
                            "Delivery",
                            isOn: $cafeOrderingSettings.deliveryEnabled
                        )
                        
                        if cafeOrderingSettings.deliveryEnabled {
                            
                            VStack(alignment: .leading, spacing: 14) {
                                
                                Text("Delivery Settings")
                                    .font(.headline)
                                
                                // Cafe Address
                                VStack(alignment: .leading, spacing: 8) {
                                    
                                    Text("Cafe Address")
                                        .font(.subheadline.weight(.medium))
                                    
                                    Text(
                                        "This address is used as the centre of the delivery radius."
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 10) {
                                        
                                        TextField(
                                            "Enter cafe street address",
                                            text: $cafeOrderingSettings.cafeAddress
                                        )
                                        .textFieldStyle(.roundedBorder)
                                        
                                        Button {
                                            verifyCafeAddress()
                                        } label: {
                                            
                                            if isVerifyingCafeAddress {
                                                ProgressView()
                                                    .controlSize(.small)
                                            } else {
                                                Text("Verify Address")
                                            }
                                        }
                                        .disabled(
                                            isVerifyingCafeAddress ||
                                            cafeOrderingSettings.cafeAddress
                                                .trimmingCharacters(
                                                    in: .whitespacesAndNewlines
                                                )
                                                .count < 5
                                        )
                                    }
                                    
                                    if cafeOrderingSettings.cafeLatitude != 0 &&
                                        cafeOrderingSettings.cafeLongitude != 0 {
                                        
                                        Label(
                                            "Address verified",
                                            systemImage: "checkmark.circle.fill"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    }
                                }
                                
                                // Delivery Radius
                                HStack {
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Delivery Radius")
                                            .font(.subheadline.weight(.medium))
                                        
                                        Text("Maximum straight-line distance from the cafe.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    TextField(
                                        "",
                                        value: $cafeOrderingSettings.deliveryRadiusKm,
                                        format: .number.precision(.fractionLength(1))
                                    )
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 70)
                                    
                                    Text("km")
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Delivery Fee
                                HStack {
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Delivery Fee")
                                            .font(.subheadline.weight(.medium))
                                        
                                        Text("Added to eligible delivery orders.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("$")
                                        .foregroundStyle(.secondary)
                                    
                                    TextField(
                                        "",
                                        value: $cafeOrderingSettings.deliveryFee,
                                        format: .number.precision(.fractionLength(2))
                                    )
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                }
                                
                                // Minimum Order
                                HStack {
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Minimum Order")
                                            .font(.subheadline.weight(.medium))
                                        
                                        Text("Minimum food and drink total required for delivery.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("$")
                                        .foregroundStyle(.secondary)
                                    
                                    TextField(
                                        "",
                                        value: $cafeOrderingSettings.minimumDeliveryOrder,
                                        format: .number.precision(.fractionLength(2))
                                    )
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                }
                            }
                            .padding(.leading, 24)
                            .padding(.top, 4)
                        }
                        
                        Divider()
                        
                        Toggle(
                            "ASAP Orders",
                            isOn: $cafeOrderingSettings.asapEnabled
                        )
                        
                        Toggle(
                            "Scheduled Orders",
                            isOn: $cafeOrderingSettings.scheduledOrderingEnabled
                        )
                        
                        Divider()
                        
                        HStack {
                            
                            VStack(alignment: .leading, spacing: 5) {
                                
                                Text("Preparation Time")
                                    .font(.headline)
                                
                                Text(
                                    "Minimum time needed before an order can be ready for pickup."
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Picker(
                                "",
                                selection: $cafeOrderingSettings.preparationTimeMinutes
                            ) {
                                Text("15 minutes").tag(15)
                                Text("20 minutes").tag(20)
                                Text("30 minutes").tag(30)
                                Text("45 minutes").tag(45)
                                Text("60 minutes").tag(60)
                            }
                            .labelsHidden()
                            .frame(width: 150)
                        }
                        
                        Divider()
                        
                        Text("Opening Hours")
                            .font(.headline)
                        
                        Text(
                            "Customers can only select pickup or delivery times within these hours."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        cafeDayHoursRow(
                            title: "Monday",
                            hours: $cafeOrderingSettings.monday
                        )
                        
                        cafeDayHoursRow(
                            title: "Tuesday",
                            hours: $cafeOrderingSettings.tuesday
                        )
                        
                        cafeDayHoursRow(
                            title: "Wednesday",
                            hours: $cafeOrderingSettings.wednesday
                        )
                        
                        cafeDayHoursRow(
                            title: "Thursday",
                            hours: $cafeOrderingSettings.thursday
                        )
                        
                        cafeDayHoursRow(
                            title: "Friday",
                            hours: $cafeOrderingSettings.friday
                        )
                        
                        cafeDayHoursRow(
                            title: "Saturday",
                            hours: $cafeOrderingSettings.saturday
                        )
                        
                        cafeDayHoursRow(
                            title: "Sunday",
                            hours: $cafeOrderingSettings.sunday
                        )
                        
                        Divider()
                        
                        HStack {
                            
                            if isLoadingCafeOrderingSettings {
                                
                                ProgressView()
                                    .controlSize(.small)
                                
                                Text("Loading settings...")
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let cafeOrderingSettingsMessage {
                                
                                Text(cafeOrderingSettingsMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                
                                Task {
                                    await saveCafeOrderingSettings()
                                }
                                
                            } label: {
                                
                                if isSavingCafeOrderingSettings {
                                    
                                    ProgressView()
                                        .controlSize(.small)
                                    
                                } else {
                                    
                                    Label(
                                        "Save Cafe Settings",
                                        systemImage: "checkmark.circle.fill"
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(
                                isSavingCafeOrderingSettings ||
                                isLoadingCafeOrderingSettings
                            )
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
                    
                    // MARK: - Account
                    
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Label(
                            "Account",
                            systemImage: "person.crop.circle"
                        )
                        .font(.title2.bold())
                        
                        Text(
                            "Manage the LunchBoxManager account."
                        )
                        .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        HStack {
                            
                            VStack(alignment: .leading, spacing: 5) {
                                
                                Text("Signed In As")
                                    .font(.headline)
                                
                                Text(
                                    Auth.auth().currentUser?.email
                                    ?? "Unknown account"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                newPassword = ""
                                confirmPassword = ""
                                passwordMessage = nil
                                showChangePassword = true
                            } label: {
                                
                                Label(
                                    "Change Password",
                                    systemImage: "key"
                                )
                            }
                        }
                        
                        if let passwordMessage {
                            
                            Divider()
                            
                            Text(passwordMessage)
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
        }
        .task {
            await loadCafeOrderingSettings()
        }
        .sheet(isPresented: $showChangePassword) {
            
            VStack(alignment: .leading, spacing: 18) {
                
                Text("Change Password")
                    .font(.title2.bold())
                
                Text(
                    "Enter a new password for your LunchBoxManager account."
                )
                .foregroundStyle(.secondary)
                
                SecureField(
                    "New Password",
                    text: $newPassword
                )
                .textFieldStyle(.roundedBorder)
                
                SecureField(
                    "Confirm New Password",
                    text: $confirmPassword
                )
                .textFieldStyle(.roundedBorder)
                
                HStack {
                    
                    Button("Cancel") {
                        showChangePassword = false
                    }
                    
                    Spacer()
                    
                    Button("Change Password") {
                        changePassword()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        newPassword.isEmpty ||
                        confirmPassword.isEmpty ||
                        isChangingPassword
                    )
                }
            }
            .padding(24)
            .frame(width: 420)
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
    
    @ViewBuilder
    private func cafeDayHoursRow(
        title: String,
        hours: Binding<CafeDayHours>
    ) -> some View {
        
        HStack(spacing: 16) {
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(
                    width: 100,
                    alignment: .leading
                )
            
            Toggle(
                "Closed",
                isOn: hours.isClosed
            )
            .toggleStyle(.checkbox)
            .frame(width: 80)
            
            if !hours.wrappedValue.isClosed {
                
                Text("Open")
                
                TextField(
                    "07:00",
                    text: hours.openTime
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 75)
                
                Text("Close")
                
                TextField(
                    "15:00",
                    text: hours.closeTime
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 75)
            }
            
            Spacer()
        }
    }
    
    private func loadCafeOrderingSettings() async {
        
        isLoadingCafeOrderingSettings = true
        cafeOrderingSettingsMessage = nil
        
        do {
            
            cafeOrderingSettings =
            try await cafeOrderingSettingsService.loadSettings()
            
        } catch {
            
            cafeOrderingSettingsMessage =
            "Could not load Cafe settings: \(error.localizedDescription)"
        }
        
        isLoadingCafeOrderingSettings = false
    }
    
    private func saveCafeOrderingSettings() async {
        
        isSavingCafeOrderingSettings = true
        cafeOrderingSettingsMessage = nil
        
        do {
            
            try await cafeOrderingSettingsService.saveSettings(
                cafeOrderingSettings
            )
            
            cafeOrderingSettingsMessage =
            "Cafe settings saved successfully."
            
        } catch {
            
            cafeOrderingSettingsMessage =
            "Could not save Cafe settings: \(error.localizedDescription)"
        }
        
        isSavingCafeOrderingSettings = false
    }
    
    private func changePassword() {
        
        passwordMessage = nil
        
        guard newPassword.count >= 6 else {
            passwordMessage =
            "Password must be at least 6 characters."
            return
        }
        
        guard newPassword == confirmPassword else {
            passwordMessage =
            "The passwords do not match."
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            passwordMessage =
            "No Manager account is currently signed in."
            return
        }
        
        isChangingPassword = true
        
        user.updatePassword(
            to: newPassword
        ) { error in
            
            DispatchQueue.main.async {
                
                isChangingPassword = false
                
                if let error {
                    
                    let nsError = error as NSError
                    
                    if nsError.code ==
                        AuthErrorCode.requiresRecentLogin.rawValue {
                        
                        passwordMessage =
                        "For security, please sign out and sign in again before changing your password."
                        
                    } else {
                        
                        passwordMessage =
                        "Password change failed: \(error.localizedDescription)"
                    }
                    
                    return
                }
                
                passwordMessage =
                "Password changed successfully."
                
                newPassword = ""
                confirmPassword = ""
                showChangePassword = false
            }
        }
    }
    private func verifyCafeAddress() {

        isVerifyingCafeAddress = true

        Task {
            do {
                let result = try await
                    CafeLocationService.shared
                        .geocodeCafeAddress(
                            cafeOrderingSettings.cafeAddress
                        )

                cafeOrderingSettings.cafeAddress =
                    result.address

                cafeOrderingSettings.cafeLatitude =
                    result.latitude

                cafeOrderingSettings.cafeLongitude =
                    result.longitude

                isVerifyingCafeAddress = false

            } catch {

                isVerifyingCafeAddress = false

                cafeOrderingSettings.cafeLatitude = 0
                cafeOrderingSettings.cafeLongitude = 0

                cafeOrderingSettingsMessage =
                    error.localizedDescription
            }
        }
    }
    
}  // ← your existing line 430

#Preview {
SettingsView()
}
