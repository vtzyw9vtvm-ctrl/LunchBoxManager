import SwiftUI

struct LunchMenuView: View {

    @State private var viewModel = MenuViewModel()

    @State private var showingAddCategory = false
    @State private var categoryName = ""
    @State private var categoryIcon = "🍔"

    @State private var categoryToDelete: LunchCategory?
    @State private var editingCategory: LunchCategory?

    var body: some View {

        NavigationStack {

            ScrollView {

                LazyVStack(spacing: 18) {

                    ForEach(viewModel.categories) { category in

                        NavigationLink {

                            LunchCategoryView(
                                category: category,
                                viewModel: viewModel
                            )

                        } label: {

                            CategoryCardView(category: category)

                        }
                        .buttonStyle(.plain)

                        .contextMenu {

                            Button("Edit Category") {

                                editingCategory = category
                                categoryName = category.name
                                categoryIcon = category.icon

                            }

                            Divider()

                            Button("Delete Category", role: .destructive) {

                                categoryToDelete = category

                            }

                        }

                    }

                }
                .padding()

            }
            .navigationTitle("Lunch Menu")

            .toolbar {

                ToolbarItem {

                    Button {

                        categoryName = ""
                        categoryIcon = "🍔"
                        showingAddCategory = true

                    } label: {

                        Label("Add Category", systemImage: "plus")

                    }

                }

            }

            .sheet(isPresented: $showingAddCategory) {

                NavigationStack {

                    Form {

                        TextField("Category Name", text: $categoryName)
                        TextField("Emoji", text: $categoryIcon)

                    }

                    .navigationTitle("New Category")

                    .toolbar {

                        ToolbarItem(placement: .cancellationAction) {

                            Button("Cancel") {
                                showingAddCategory = false
                            }

                        }

                        ToolbarItem(placement: .confirmationAction) {

                            Button("Add") {

                                viewModel.categories.append(
                                    LunchCategory(
                                        name: categoryName,
                                        icon: categoryIcon.isEmpty ? "🍽️" : categoryIcon
                                    )
                                )

                                viewModel.save()

                                showingAddCategory = false

                            }

                        }

                    }

                }

            }

            .sheet(item: $editingCategory) { category in

                NavigationStack {

                    Form {

                        TextField("Category Name", text: $categoryName)
                        TextField("Emoji", text: $categoryIcon)

                    }

                    .navigationTitle("Edit Category")

                    .toolbar {

                        ToolbarItem(placement: .cancellationAction) {

                            Button("Cancel") {

                                editingCategory = nil

                            }

                        }

                        ToolbarItem(placement: .confirmationAction) {

                            Button("Save") {

                                if let index = viewModel.categories.firstIndex(where: { $0.id == category.id }) {

                                    viewModel.categories[index].name = categoryName
                                    viewModel.categories[index].icon = categoryIcon

                                    viewModel.save()

                                }

                                editingCategory = nil

                            }

                        }

                    }

                }

            }

            .alert(
                "Delete Category?",
                isPresented: Binding(
                    get: { categoryToDelete != nil },
                    set: { if !$0 { categoryToDelete = nil } }
                )
            ) {

                Button("Delete", role: .destructive) {

                    if let category = categoryToDelete,
                       let index = viewModel.categories.firstIndex(where: { $0.id == category.id }) {

                        viewModel.categories.remove(at: index)
                        viewModel.save()

                    }

                    categoryToDelete = nil

                }

                Button("Cancel", role: .cancel) {

                    categoryToDelete = nil

                }

            } message: {

                Text("This will permanently delete the category and all menu items inside it.")

            }

        }

    }

}

#Preview {

    LunchMenuView()

}
