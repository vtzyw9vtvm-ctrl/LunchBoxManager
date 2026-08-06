import SwiftUI

struct LunchCategoryView: View {

    let category: LunchCategory
    @Bindable var viewModel: MenuViewModel

    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var editingItem: LunchMenuItem?

    private var filteredItems: [LunchMenuItem] {

        let items = viewModel.items(for: category)

        if searchText.isEmpty {
            return items
        }

        return items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }

    }

    var body: some View {

        VStack(spacing: 16) {

            SearchBar(text: $searchText)

            List {

                Section {

                    Button {

                        showingAddItem = true

                    } label: {

                        Label("Add Item", systemImage: "plus.circle.fill")

                    }

                    ForEach(filteredItems) { item in

                        Button {

                            editingItem = item

                        } label: {

                            MenuItemCardView(item: item)

                        }
                        .buttonStyle(.plain)

                        .contextMenu {

                            Button {

                                duplicate(item)

                            } label: {

                                Label("Duplicate", systemImage: "plus.square.on.square")

                            }

                            Divider()

                            Button(role: .destructive) {

                                delete(item)

                            } label: {

                                Label("Delete", systemImage: "trash")

                            }

                        }

                    }
                    .onDelete(perform: deleteItems)
                    .onMove(perform: moveItems)

                }

            }

        }
        .padding()
        .navigationTitle(category.name)

        .sheet(isPresented: $showingAddItem) {

            AddMenuItemView { newItem in

                var items = viewModel.items(for: category)
                items.append(newItem)
                viewModel.setItems(items, for: category)

            }

        }

        .sheet(item: $editingItem) { item in

            AddMenuItemView(item: item) { updatedItem in

                var items = viewModel.items(for: category)

                if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
                    items[index] = updatedItem
                }

                viewModel.setItems(items, for: category)

            }

        }

    }

    private func moveItems(from source: IndexSet, to destination: Int) {

        var items = viewModel.items(for: category)
        items.move(fromOffsets: source, toOffset: destination)
        viewModel.setItems(items, for: category)

    }

    private func deleteItems(at offsets: IndexSet) {

        var items = viewModel.items(for: category)

        let filtered = filteredItems
        let idsToDelete = offsets.map { filtered[$0].id }

        items.removeAll { idsToDelete.contains($0.id) }

        viewModel.setItems(items, for: category)

    }

    private func duplicate(_ item: LunchMenuItem) {

        var items = viewModel.items(for: category)

        let copy = LunchMenuItem(
            name: item.name + " Copy",
            description: item.description,
            category: item.category,
            price: item.price,
            costPrice: item.costPrice,
            gstIncluded: item.gstIncluded,
            isActive: item.isActive,
            isFeatured: item.isFeatured,
            imageName: item.imageName
        )

        items.append(copy)

        viewModel.setItems(items, for: category)

        editingItem = copy

    }

    private func delete(_ item: LunchMenuItem) {

        var items = viewModel.items(for: category)

        items.removeAll { $0.id == item.id }

        viewModel.setItems(items, for: category)

    }

}

#Preview {

    LunchCategoryView(
        category: LunchCategory(
            name: "Hot Food",
            icon: "🍔"
        ),
        viewModel: MenuViewModel()
    )

}
