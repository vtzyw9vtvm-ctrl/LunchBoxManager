import SwiftUI

struct MenuWorkspaceView: View {
    
    @State private var menuManager = MenuViewModel()
    
    @State private var selectedCategory: LunchCategory?
    @State private var selectedItemID: UUID?
    @State private var showDeleteCategoryConfirmation = false
    @State private var categoryPendingDeletion: LunchCategory?
    @State private var showDeleteItemConfirmation = false
    @State private var itemPendingDeletion: LunchMenuItem?
    
    
    var body: some View {
        
        HSplitView {
            
            // MARK: Categories
            
            VStack(spacing: 0) {
                
                toolbar(
                    title: "Categories",
                    systemImage: "plus"
                ) {
                    
                    let category = menuManager.addCategory()
                    
                    selectedCategory = category
                    selectedItemID = nil
                    
                }
                
                Divider()
                
                List(menuManager.categories,
                     selection: $selectedCategory) { category in
                    
                    HStack(spacing: 12) {

                        Text(category.icon)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {

                            Text(category.name)
                                .font(.headline)

                            Text("\(menuManager.items(for: category).count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                        }

                    }
                    .tag(category)

                    .contextMenu {

                        Button {

                            let newCategory = menuManager.addCategory()
                            selectedCategory = newCategory

                        } label: {

                            Label("New Category", systemImage: "plus")

                        }

                        Divider()

                        Button(role: .destructive) {

                            categoryPendingDeletion = category
                            showDeleteCategoryConfirmation = true

                        } label: {

                            Label("Delete Category", systemImage: "trash")

                        }

                    }
                    
                }
                
            }
            .frame(minWidth: 260,
                   idealWidth: 280,
                   maxWidth: 320)
            
            // MARK: Menu Items
            
            VStack(spacing: 0) {
                
                toolbar(
                    title: selectedCategory?.name ?? "Menu Items",
                    systemImage: "plus"
                ) {
                    
                    guard let category = selectedCategory else { return }
                    
                    let item = menuManager.addItem(to: category)
                    
                    selectedItemID = item.id
                    
                }
                
                Divider()
                
                if let category = selectedCategory {
                    
                    ScrollView {
                        
                        LazyVStack(spacing: 12) {
                            
                            ForEach(menuManager.items(for: category)) { item in
                                
                                MenuItemCardView(
                                    item: item,
                                    isSelected: selectedItemID == item.id,

                                    onDuplicate: {

                                        guard let category = selectedCategory else { return }

                                        let copy = menuManager.duplicateItem(item, in: category)

                                        selectedItemID = copy.id

                                    },

                                    onDelete: {

                                        itemPendingDeletion = item
                                        showDeleteItemConfirmation = true

                                    }
                                )
                                .contentShape(Rectangle())

                                .onTapGesture {

                                    withAnimation(.easeInOut(duration: 0.15)) {

                                        selectedItemID = item.id

                                    }

                                }
                                
                            }
                            
                        }
                        .padding()
                        
                    }
                    
                } else {
                    
                    ContentUnavailableView(
                        "Select Category",
                        systemImage: "folder"
                    )
                    
                }
                
            }
            .frame(minWidth: 520,
                   maxWidth: .infinity)
            
            // MARK: Inspector
            
            // MARK: Inspector

            Group {

                if
                    let category = selectedCategory,
                    let id = selectedItemID,
                    let index = menuManager.items(for: category).firstIndex(where: { $0.id == id })
                {

                    MenuItemInspector(

                        item: Binding(

                            get: {

                                menuManager.items(for: category)[index]

                            },

                            set: {

                                var items = menuManager.items(for: category)

                                items[index] = $0

                                menuManager.setItems(
                                    items,
                                    for: category
                                )

                            }

                        )

                    )

                }
                else if let category = selectedCategory,
                        let index = menuManager.categories.firstIndex(where: { $0.id == category.id }) {

                    CategoryInspector(

                        category: Binding(

                            get: {

                                menuManager.categories[index]

                            },

                            set: {

                                menuManager.updateCategory($0)

                            }

                        )

                    )

                }
                else {

                    ContentUnavailableView(
                        "Select Category",
                        systemImage: "folder"
                    )

                }

            }
            .frame(width: 420)
            
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
        
        .navigationTitle("Menu")
        .onAppear {

            guard selectedCategory == nil else { return }

            guard let firstCategory = menuManager.categories.first else { return }

            selectedCategory = firstCategory

            let items = menuManager.items(for: firstCategory)

            if let first = items.first {

                selectedItemID = first.id

            } else {

                let newItem = menuManager.addItem(to: firstCategory)

                selectedItemID = newItem.id

            }

        }
        
        .onChange(of: selectedCategory) {

            selectedItemID = nil

        }
            
        
        .confirmationDialog(
            "Delete Menu Item",
            isPresented: $showDeleteItemConfirmation,
            titleVisibility: .visible
        ) {

            Button("Delete", role: .destructive) {

                guard
                    let category = selectedCategory,
                    let item = itemPendingDeletion
                else { return }

                menuManager.deleteItem(
                    item,
                    from: category
                )

                let remaining = menuManager.items(for: category)

                selectedItemID = remaining.first?.id

                itemPendingDeletion = nil

            }

            Button("Cancel", role: .cancel) {

                itemPendingDeletion = nil

            }

        } message: {

            Text("Are you sure you want to delete \"\(itemPendingDeletion?.name ?? "")\"?")

        }
        .confirmationDialog(
            "Delete Category",
            isPresented: $showDeleteCategoryConfirmation,
            titleVisibility: .visible
        ) {

            Button("Delete", role: .destructive) {

                guard let category = categoryPendingDeletion else { return }

                menuManager.deleteCategory(category)

                selectedCategory = menuManager.categories.first
                selectedItemID = menuManager.items(for: selectedCategory ?? LunchCategory(name: "", icon: "")).first?.id

                categoryPendingDeletion = nil

            }

            Button("Cancel", role: .cancel) {

                categoryPendingDeletion = nil

            }

        } message: {

            Text("Delete \"\(categoryPendingDeletion?.name ?? "")\"?")

        }
    }
    

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

            Button(action: action) {

                Image(systemName: systemImage)
                    .font(.title3)

            }
            .buttonStyle(.borderless)

        }
        .padding()

    }

}

#Preview {

    MenuWorkspaceView()

}
