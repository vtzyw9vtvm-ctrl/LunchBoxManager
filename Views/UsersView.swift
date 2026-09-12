import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UsersView: View {

    @State private var users: [LunchBoxUser] = []
    @State private var selectedUserID: String?
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var adminUserIDs: Set<String> = []
    @State private var isLoadingAdmins = true
    @State private var adminErrorMessage: String?

    private let db = Firestore.firestore()
    private let adminService = FirebaseAdminService()

    private var filteredUsers: [LunchBoxUser] {

        let sorted = users.sorted {
            $0.displayName.localizedCaseInsensitiveCompare(
                $1.displayName
            ) == .orderedAscending
        }

        guard !searchText.isEmpty else {
            return sorted
        }

        return sorted.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText) ||
            user.mobile.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {

        VStack(spacing: 0) {

            PageBannerView(
                title: "Users",
                subtitle: "Registered LunchBox parents and account access",
                systemImage: "person.2.fill",
                color: .lunchBoxBlue
            )

            HSplitView {

                // MARK: - User List

                VStack(spacing: 0) {

                    HStack {

                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField(
                            "Search users",
                            text: $searchText
                        )
                        .textFieldStyle(.plain)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                Color(
                                    nsColor: .controlBackgroundColor
                                )
                            )
                    )
                    .padding()

                    Divider()

                    if isLoading {

                        Spacer()

                        ProgressView("Loading users…")

                        Spacer()

                    } else if let errorMessage {

                        Spacer()

                        VStack(spacing: 10) {

                            Image(
                                systemName:
                                    "exclamationmark.triangle"
                            )
                            .font(.largeTitle)

                            Text("Unable to Load Users")
                                .font(.headline)

                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()

                        Spacer()

                    } else if filteredUsers.isEmpty {

                        Spacer()

                        ContentUnavailableView(
                            "No Users",
                            systemImage: "person.2",
                            description: Text(
                                searchText.isEmpty
                                    ? "No registered LunchBox users were found."
                                    : "No users match your search."
                            )
                        )

                        Spacer()

                    } else {

                        List(
                            filteredUsers,
                            selection: $selectedUserID
                        ) { user in

                            HStack {

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(user.displayName)
                                        .font(.headline)

                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if isLoadingAdmins {

                                    ProgressView()
                                        .controlSize(.small)

                                } else {

                                    Text(
                                        adminUserIDs.contains(user.id)
                                            ? "ADMIN"
                                            : "PARENT"
                                    )
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(
                                                adminUserIDs.contains(user.id)
                                                    ? Color.orange.opacity(0.18)
                                                    : Color.secondary.opacity(0.12)
                                            )
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                            .tag(user.id)
                        }
                        .listStyle(.sidebar)
                    }

                    Divider()

                    HStack {

                        Text(
                            "\(filteredUsers.count) user\(filteredUsers.count == 1 ? "" : "s")"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(12)
                }
                .frame(minWidth: 280, idealWidth: 330)

                // MARK: - User Detail

                if let selectedUser {

                    UserDetailView(
                        user: selectedUser,
                        isAdmin: adminUserIDs.contains(
                            selectedUser.id
                        ),
                        adminService: adminService,
                        onAdminAccessChanged: {
                            await loadAdmins()
                        },
                        onUserDeleted: {
                            await reloadUsers()
                        }
                    )
                        .id(selectedUser.id)
                        .frame(
                            minWidth: 420,
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )

                } else {

                    ContentUnavailableView(
                        "Select a User",
                        systemImage: "person.crop.circle",
                        description: Text(
                            "Choose a registered user to view their account details."
                        )
                    )
                    .frame(
                        minWidth: 420,
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                }
            }
        }
        .task {

            loadUsers()

            await loadAdmins()
        }
    }

    private var selectedUser: LunchBoxUser? {

        guard let selectedUserID else {
            return nil
        }

        return users.first {
            $0.id == selectedUserID
        }
    }

    private func reloadUsers() async {

        await MainActor.run {
            selectedUserID = nil
        }

        loadUsers()

        try? await Task.sleep(
            for: .milliseconds(500)
        )
    }
    
    private func loadUsers() {

        isLoading = true
        errorMessage = nil

        db.collection("users")
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {

                    isLoading = false

                    if let error {
                        errorMessage =
                            error.localizedDescription
                        return
                    }

                    guard let documents =
                            snapshot?.documents else {
                        users = []
                        return
                    }

                    users = documents.map { document in

                        let data = document.data()

                        return LunchBoxUser(
                            id: document.documentID,
                            firstName:
                                data["firstName"] as? String
                                ?? "",
                            lastName:
                                data["lastName"] as? String
                                ?? "",
                            email:
                                data["email"] as? String
                                ?? "",
                            mobile:
                                data["mobile"] as? String
                                ?? ""
                        )
                    }

                    if selectedUserID == nil {
                        selectedUserID = users.first?.id
                    }
                }
            }
    }
    
    private func loadAdmins() async {

        isLoadingAdmins = true
        adminErrorMessage = nil

        do {

            adminUserIDs =
                try await adminService
                    .loadAdminUserIDs()

        } catch {

            adminErrorMessage =
                error.localizedDescription
        }

        isLoadingAdmins = false
    }
    
}


// MARK: - LunchBox User

private struct LunchBoxUser: Identifiable {

    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let mobile: String

    var displayName: String {

        let name = "\(firstName) \(lastName)"
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return name.isEmpty
            ? "Unnamed User"
            : name
    }
}


// MARK: - LunchBox Child

private struct LunchBoxChild: Identifiable {

    let id: String
    let firstName: String
    let lastName: String
    let school: String
    let yearLevel: String
    let className: String
    let medicalNotes: String

    var displayName: String {

        let name = "\(firstName) \(lastName)"
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return name.isEmpty
            ? "Unnamed Child"
            : name
    }
}


// MARK: - User Detail

private struct UserDetailView: View {

    let user: LunchBoxUser
    let isAdmin: Bool
    let adminService: FirebaseAdminService
    let onAdminAccessChanged: () async -> Void
    let onUserDeleted: () async -> Void

    @State private var children: [LunchBoxChild] = []
    @State private var isLoadingChildren = true
    @State private var childrenError: String?

    @State private var showAdminConfirmation = false
    @State private var isChangingAdminAccess = false
    @State private var adminAccessMessage: String?

    @State private var showDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String?

    private let db = Firestore.firestore()

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                // MARK: Parent

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Image(
                        systemName:
                            "person.crop.circle.fill"
                    )
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)

                    Text(user.displayName)
                        .font(.largeTitle.bold())

                    HStack(spacing: 8) {

                        Text(
                            isAdmin
                                ? "Administrator"
                                : "Parent Account"
                        )
                        .font(.headline)
                        .foregroundStyle(.secondary)

                        Text(
                            isAdmin
                                ? "ADMIN"
                                : "PARENT"
                        )
                        .font(.caption.bold())
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    isAdmin
                                        ? Color.orange.opacity(0.18)
                                        : Color.secondary.opacity(0.12)
                                )
                        )
                    }
                }

                Divider()

                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {

                    DetailRow(
                        title: "Email",
                        value: user.email,
                        systemImage: "envelope"
                    )

                    DetailRow(
                        title: "Mobile",
                        value: user.mobile.isEmpty
                            ? "Not provided"
                            : user.mobile,
                        systemImage: "phone"
                    )
                }

                Divider()

                // MARK: - Account Access

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    HStack {

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text("Account Access")
                                .font(.headline)

                            Text(
                                isAdmin
                                    ? "This user can sign in to LunchBox Manager."
                                    : "This user has parent app access only."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if user.id ==
                            Auth.auth().currentUser?.uid {

                            Text("Your Account")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                        } else {

                            Button {
                                showAdminConfirmation = true
                            } label: {

                                if isChangingAdminAccess {

                                    ProgressView()
                                        .controlSize(.small)

                                } else {

                                    Label(
                                        isAdmin
                                            ? "Remove Admin Access"
                                            : "Grant Admin Access",
                                        systemImage:
                                            isAdmin
                                                ? "person.badge.minus"
                                                : "person.badge.plus"
                                    )
                                }
                            }
                            .disabled(isChangingAdminAccess)
                        }
                    }
                    if user.id != Auth.auth().currentUser?.uid {

                        Divider()

                        HStack {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("Delete Account")
                                    .font(.headline)

                                Text(
                                    "Permanently delete this user's login, profile and children."
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                deleteErrorMessage = nil
                                showDeleteConfirmation = true
                            } label: {

                                if isDeletingAccount {

                                    ProgressView()
                                        .controlSize(.small)

                                } else {

                                    Label(
                                        "Delete Account…",
                                        systemImage: "trash"
                                    )
                                }
                            }
                            .disabled(
                                isDeletingAccount ||
                                isChangingAdminAccess
                            )
                        }
                    }
                    if let adminAccessMessage {

                        Text(adminAccessMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let deleteErrorMessage {

                        Text(deleteErrorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
                
                // MARK: Children

                VStack(
                    alignment: .leading,
                    spacing: 16
                ) {

                    HStack {

                        Label(
                            "Children",
                            systemImage: "figure.2.and.child.holdinghands"
                        )
                        .font(.title2.bold())

                        Spacer()

                        if !isLoadingChildren &&
                            childrenError == nil {

                            Text(
                                "\(children.count)"
                            )
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        }
                    }

                    if isLoadingChildren {

                        HStack {

                            ProgressView()
                                .controlSize(.small)

                            Text("Loading children…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)

                    } else if let childrenError {

                        Label(
                            childrenError,
                            systemImage:
                                "exclamationmark.triangle"
                        )
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)

                    } else if children.isEmpty {

                        Text(
                            "No children have been added to this account."
                        )
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)

                    } else {

                        ForEach(children) { child in

                            ChildCard(child: child)
                        }
                    }
                }

                Spacer()
            }
            .padding(30)
            .frame(
                maxWidth: 700,
                alignment: .leading
            )
        }
        .task {
            loadChildren()
        }
        .confirmationDialog(
            isAdmin
                ? "Remove Administrator Access?"
                : "Grant Administrator Access?",
            isPresented: $showAdminConfirmation
        ) {

            Button(
                isAdmin
                    ? "Remove Admin Access"
                    : "Grant Admin Access",
                role: isAdmin ? .destructive : nil
            ) {

                Task {
                    await changeAdminAccess()
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}

        } message: {

            Text(
                isAdmin
                    ? "\(user.displayName) will no longer be able to sign in to LunchBox Manager."
                    : "\(user.displayName) will be able to sign in to LunchBox Manager and access Manager functions."
            )
        }
        .confirmationDialog(
            "Permanently Delete \(user.displayName)?",
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete Account Permanently",
                role: .destructive
            ) {
                Task {
                    await deleteAccount()
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}

        } message: {

            Text(
                "This will permanently delete the LunchBox login, parent profile and children for \(user.displayName). Historical orders will be retained. This cannot be undone."
            )
        }
    }
    private func deleteAccount() async {

        isDeletingAccount = true
        deleteErrorMessage = nil

        do {

            try await adminService.deleteUser(
                userID: user.id
            )

            await onAdminAccessChanged()
            await onUserDeleted()

        } catch {

            deleteErrorMessage =
                "Account deletion failed: \(error.localizedDescription)"

            isDeletingAccount = false
        }
    }
    private func changeAdminAccess() async {

        isChangingAdminAccess = true
        adminAccessMessage = nil

        do {

            try await adminService.setAdminAccess(
                userID: user.id,
                makeAdmin: !isAdmin
            )

            await onAdminAccessChanged()

            adminAccessMessage =
                isAdmin
                    ? "Administrator access removed."
                    : "Administrator access granted."

        } catch {

            adminAccessMessage =
                "Access change failed: \(error.localizedDescription)"
        }

        isChangingAdminAccess = false
    }
    private func loadChildren() {

        isLoadingChildren = true
        childrenError = nil

        db.collection("users")
            .document(user.id)
            .collection("children")
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {

                    isLoadingChildren = false

                    if let error {
                        childrenError =
                            error.localizedDescription
                        return
                    }

                    guard let documents =
                            snapshot?.documents else {
                        children = []
                        return
                    }

                    children = documents.map { document in

                        let data = document.data()

                        return LunchBoxChild(
                            id: document.documentID,
                            firstName:
                                data["firstName"] as? String
                                ?? "",
                            lastName:
                                data["lastName"] as? String
                                ?? "",
                            school:
                                data["school"] as? String
                                ?? "",
                            yearLevel:
                                data["yearLevel"] as? String
                                ?? "",
                            className:
                                data["className"] as? String
                                ?? "",
                            medicalNotes:
                                data["medicalNotes"] as? String
                                ?? ""
                        )
                    }
                    .sorted {
                        $0.displayName
                            .localizedCaseInsensitiveCompare(
                                $1.displayName
                            ) == .orderedAscending
                    }
                }
            }
    }
}


// MARK: - Child Card

private struct ChildCard: View {

    let child: LunchBoxChild

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Image(
                    systemName:
                        "person.crop.circle"
                )
                .font(.title2)
                .foregroundStyle(.secondary)

                Text(child.displayName)
                    .font(.headline)

                Spacer()
            }

            if !child.school.isEmpty {

                Label(
                    child.school,
                    systemImage: "building.2"
                )
                .font(.subheadline)
            }

            HStack(spacing: 8) {

                if !child.yearLevel.isEmpty {

                    Label(
                        child.yearLevel,
                        systemImage: "graduationcap"
                    )
                }

                if !child.yearLevel.isEmpty &&
                    !child.className.isEmpty {

                    Text("•")
                        .foregroundStyle(.secondary)
                }

                if !child.className.isEmpty {

                    Text(child.className)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !child.medicalNotes
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {

                Divider()

                HStack(
                    alignment: .top,
                    spacing: 8
                ) {

                    Image(
                        systemName:
                            "cross.case"
                    )
                    .foregroundStyle(.secondary)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text("Medical Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(child.medicalNotes)
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    Color(
                        nsColor:
                            .controlBackgroundColor
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color.secondary.opacity(0.15),
                    lineWidth: 1
                )
        )
    }
}


// MARK: - Detail Row

private struct DetailRow: View {

    let title: String
    let value: String
    let systemImage: String

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            Image(systemName: systemImage)
                .frame(width: 22)
                .foregroundStyle(.secondary)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
    }
}


#Preview {
    UsersView()
}
