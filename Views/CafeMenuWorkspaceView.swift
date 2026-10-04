import SwiftUI

struct CafeMenuWorkspaceView: View {

    @State private var menuManager = CafeMenuViewModel()
    @State private var modifierManager = CafeModifierManager()
    
    private let firebaseMenuService = CafeFirebaseMenuService()

    @State private var isPublishing = false
    @State private var publishMessage: String?

    @State private var selectedCategory: LunchCategory?
    @State private var selectedItemID: UUID?

    @State private var searchText = ""
    @State private var showInactive = true

    @State private var showDeleteCategoryConfirmation = false
    @State private var categoryPendingDeletion: LunchCategory?

    @State private var showDeleteItemConfirmation = false
    @State private var itemPendingDeletion: LunchMenuItem?

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Page Banner

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text("CAFE MENU")
                        .font(
                            .system(
                                size: 38,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)

                    Text(
                        "Manage cafe menu items, categories and pricing"
                    )
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(0.78)
                    )
                }

                Spacer()

                Image(
                    systemName: "cup.and.saucer.fill"
                )
                .font(
                    .system(
                        size: 38,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.orange
                )
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 17)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Color(
                    red: 0.333,
                    green: 0.478,
                    blue: 0.353
                )
            )

            // MARK: - Cafe Menu Workspace

            HSplitView {

                // MARK: - Categories

                VStack(spacing: 0) {

                    toolbar(
                        title: "Categories",
                        systemImage: "plus"
                    ) {

                        let category =
                            menuManager.addCategory()

                        selectedCategory = category
                        selectedItemID = nil
                    }

                    VStack(spacing: 6) {

                        HStack {

                            Label(
                                "\(menuManager.totalMenuItems)",
                                systemImage: "fork.knife"
                            )

                            Spacer()

                            Label(
                                "\(menuManager.activeMenuItems)",
                                systemImage:
                                    "checkmark.circle.fill"
                            )
                            .foregroundStyle(.green)

                            Label(
                                "\(menuManager.featuredMenuItems)",
                                systemImage: "star.fill"
                            )
                            .foregroundStyle(.yellow)
                        }

                        HStack {

                            Text("Average")

                            Spacer()

                            Text(
                                "$\(menuManager.averageSellPrice, specifier: "%.2f")"
                            )
                            .bold()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Divider()

                    ReorderableList(
                        items: menuManager.categories,
                        onMove: {
                            categoryID,
                            index in

                            menuManager.moveCategory(
                                withId: categoryID,
                                to: index
                            )
                        }
                    ) { category in

                        HStack(spacing: 12) {

                            Text(category.icon)
                                .font(.title3)

                            VStack(
                                alignment: .leading,
                                spacing: 2
                            ) {
                                Text(category.name)
                                    .font(.headline)

                                Text(
                                    "\(menuManager.items(for: category).count) items"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(spacing: 1) {
                                Button {
                                    menuManager.moveCategoryUp(category)
                                } label: {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 10, weight: .bold))
                                        .frame(width: 20, height: 16)
                                }
                                .buttonStyle(.borderless)
                                .disabled(
                                    menuManager.categories.first?.id == category.id
                                )

                                Button {
                                    menuManager.moveCategoryDown(category)
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .frame(width: 20, height: 16)
                                }
                                .buttonStyle(.borderless)
                                .disabled(
                                    menuManager.categories.last?.id == category.id
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 8
                            )
                            .fill(
                                selectedCategory?.id
                                    == category.id
                                ? Color.accentColor
                                : Color.clear
                            )
                        )
                        .foregroundStyle(
                            selectedCategory?.id
                                == category.id
                            ? Color.white
                            : Color.primary
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = category
                        }
                        .contextMenu {

                            Button {

                                let newCategory =
                                    menuManager
                                        .addCategory()

                                selectedCategory =
                                    newCategory

                            } label: {

                                Label(
                                    "New Category",
                                    systemImage: "plus"
                                )
                            }

                            Button {

                                let copy =
                                    menuManager
                                        .duplicateCategory(
                                            category
                                        )

                                selectedCategory = copy

                            } label: {

                                Label(
                                    "Duplicate Category",
                                    systemImage:
                                        "plus.square.on.square"
                                )
                            }

                            Divider()

                            Button(
                                role: .destructive
                            ) {

                                categoryPendingDeletion =
                                    category

                                showDeleteCategoryConfirmation =
                                    true

                            } label: {

                                Label(
                                    "Delete Category",
                                    systemImage: "trash"
                                )
                            }
                        }
                    }
                }
                .frame(
                    minWidth: 200,
                    idealWidth: 220,
                    maxWidth: 260
                )

                // MARK: - Menu Items

                VStack(spacing: 0) {

                    toolbar(
                        title:
                            selectedCategory?.name
                            ?? "Menu Items",
                        systemImage: "plus"
                    ) {

                        guard let category =
                            selectedCategory
                        else {
                            return
                        }

                        let item =
                            menuManager.addItem(
                                to: category
                            )

                        selectedItemID = item.id
                    }

                    Divider()

                    HStack {

                        TextField(
                            "Search menu…",
                            text: $searchText
                        )
                        .textFieldStyle(.roundedBorder)

                        Toggle(
                            "Show Inactive",
                            isOn: $showInactive
                        )
                        .toggleStyle(.switch)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    if let category =
                        selectedCategory {

                        ReorderableList(
                            items:
                                menuManager
                                    .items(
                                        for: category
                                    )
                                    .filter {

                                        (
                                            showInactive
                                            || $0.isActive
                                        )
                                        &&
                                        (
                                            searchText.isEmpty
                                            ||
                                            $0.name
                                                .localizedCaseInsensitiveContains(
                                                    searchText
                                                )
                                            ||
                                            $0.description
                                                .localizedCaseInsensitiveContains(
                                                    searchText
                                                )
                                        )
                                    },
                            onMove: {
                                itemID,
                                index in

                                guard let category =
                                    selectedCategory
                                else {
                                    return
                                }

                                menuManager.moveItem(
                                    withId: itemID,
                                    to: index,
                                    in: category
                                )
                            }
                        ) { item in

                            MenuItemCardView(
                                item: item,
                                isSelected:
                                    selectedItemID
                                        == item.id,
                                onDuplicate: {

                                    guard
                                        let category =
                                            selectedCategory
                                    else {
                                        return
                                    }

                                    let copy =
                                        menuManager
                                            .duplicateItem(
                                                item,
                                                in: category
                                            )

                                    selectedItemID =
                                        copy.id
                                },
                                onMoveUp: {

                                    guard
                                        let category =
                                            selectedCategory
                                    else {
                                        return
                                    }

                                    menuManager
                                        .moveItemUp(
                                            item,
                                            in: category
                                        )
                                },
                                onMoveDown: {

                                    guard
                                        let category =
                                            selectedCategory
                                    else {
                                        return
                                    }

                                    menuManager
                                        .moveItemDown(
                                            item,
                                            in: category
                                        )
                                },
                                onDelete: {

                                    itemPendingDeletion =
                                        item

                                    showDeleteItemConfirmation =
                                        true
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {

                                withAnimation(
                                    .easeInOut(
                                        duration: 0.15
                                    )
                                ) {
                                    selectedItemID =
                                        item.id
                                }
                            }
                        }

                    } else {

                        ContentUnavailableView(
                            "Select Category",
                            systemImage: "folder"
                        )
                    }
                }
                .frame(
                    minWidth: 400,
                    maxWidth: .infinity
                )

                // MARK: - Inspector

                Group {

                    if
                        let category =
                            selectedCategory,
                        let id =
                            selectedItemID,
                        let index =
                            menuManager
                                .items(
                                    for: category
                                )
                                .firstIndex(
                                    where: {
                                        $0.id == id
                                    }
                                )
                    {

                        CafeMenuItemInspector(
                            item: Binding(
                                get: {

                                    menuManager
                                        .items(
                                            for: category
                                        )[index]
                                },
                                set: {

                                    var items =
                                        menuManager
                                            .items(
                                                for: category
                                            )

                                    items[index] = $0

                                    menuManager
                                        .setItems(
                                            items,
                                            for: category
                                        )
                                }
                            )
                        )

                    } else if
                        let category =
                            selectedCategory,
                        let index =
                            menuManager
                                .categories
                                .firstIndex(
                                    where: {
                                        $0.id
                                            == category.id
                                    }
                                )
                    {

                        CategoryInspector(
                            category: Binding(
                                get: {

                                    menuManager
                                        .categories[index]
                                },
                                set: {

                                    menuManager
                                        .updateCategory(
                                            $0
                                        )
                                }
                            )
                        )

                    } else {

                        ContentUnavailableView(
                            "Select Category",
                            systemImage: "folder"
                        )
                    }
                }
                .frame(width: 420)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .navigationTitle("Cafe Menu")
        
        .toolbar {

            ToolbarItem {

                Button {

                    Task {

                        isPublishing = true
                        publishMessage = nil

                        do {

                            try await firebaseMenuService.uploadMenu(
                                categories: menuManager.categories,
                                modifierGroups: modifierManager.groups
                            )

                            publishMessage =
                                "Cafe menu published successfully."

                        } catch {

                            publishMessage =
                                "Publish failed: \(error.localizedDescription)"
                        }

                        isPublishing = false
                    }

                } label: {

                    if isPublishing {

                        ProgressView()
                            .controlSize(.small)

                    } else {

                        Label(
                            "Publish Cafe Menu",
                            systemImage: "icloud.and.arrow.up"
                        )
                    }
                }
                .disabled(isPublishing)
            }
        }

        .alert(
            "Cafe Menu",
            isPresented: Binding(
                get: {
                    publishMessage != nil
                },
                set: {
                    if !$0 {
                        publishMessage = nil
                    }
                }
            )
        ) {

            Button("OK") {
                publishMessage = nil
            }

        } message: {

            Text(
                publishMessage ?? ""
            )
        }

        // MARK: - Initial Selection

        // MARK: - Initial Selection

        .onAppear {

            if selectedCategory == nil {

                selectedCategory =
                    menuManager.categories.first

                if let firstCategory =
                    selectedCategory {

                    selectedItemID =
                        menuManager
                            .items(
                                for: firstCategory
                            )
                            .first?
                            .id
                }
            }
        }

        .onChange(
            of: selectedCategory
        ) {
            selectedItemID = nil
        }

        // MARK: - Delete Item

        .confirmationDialog(
            "Delete Menu Item",
            isPresented:
                $showDeleteItemConfirmation,
            titleVisibility: .visible
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                guard
                    let category =
                        selectedCategory,
                    let item =
                        itemPendingDeletion
                else {
                    return
                }

                menuManager.deleteItem(
                    item,
                    from: category
                )

                let remaining =
                    menuManager.items(
                        for: category
                    )

                selectedItemID =
                    remaining.first?.id

                itemPendingDeletion = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
                itemPendingDeletion = nil
            }

        } message: {

            Text(
                "Are you sure you want to delete \"\(itemPendingDeletion?.name ?? "")\"?"
            )
        }

        // MARK: - Delete Category

        .confirmationDialog(
            "Delete Category",
            isPresented:
                $showDeleteCategoryConfirmation,
            titleVisibility: .visible
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                guard let category =
                    categoryPendingDeletion
                else {
                    return
                }

                menuManager.deleteCategory(
                    category
                )

                selectedCategory =
                    menuManager.categories.first

                if let firstCategory =
                    selectedCategory {

                    selectedItemID =
                        menuManager
                            .items(
                                for: firstCategory
                            )
                            .first?
                            .id

                } else {

                    selectedItemID = nil
                }

                categoryPendingDeletion = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
                categoryPendingDeletion = nil
            }

        } message: {

            Text(
                "Delete \"\(categoryPendingDeletion?.name ?? "")\"?"
            )
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private func toolbar(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        HStack {

            Text(title)
                .font(.headline)

            Spacer()

            Button(
                action: action
            ) {

                Image(
                    systemName: systemImage
                )
                .font(.title3)
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }
}

#Preview {
    CafeMenuWorkspaceView()
}
