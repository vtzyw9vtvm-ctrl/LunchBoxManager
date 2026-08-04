import SwiftUI

struct LunchCategoryView: View {

    let category: LunchCategory
    @Bindable var viewModel: MenuViewModel

    @State private var showingAddItem = false
    @State private var editingItem: LunchMenuItem?

    private var items: [LunchMenuItem] {
        get {
            viewModel.items(for: category)
        }
        set {
            viewModel.setItems(newValue, for: category)
        }
    }

    var body: some View {
        
        List {
            
            Section {
                
                ForEach(items) { item in
                    
                    Button {
                        editingItem = item
                    } label: {
                        
                        HStack(spacing: 16) {
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                )
                            
                            VStack(alignment: .leading, spacing: 6) {
                                
                                Text(item.name)
                                    .font(.headline)
                                
                                Text(item.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("$\(item.price, specifier: "%.2f")")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                    
                }
                .onMove(perform: moveItems)
                .onDelete(perform: deleteItems)
                
            } header: {
                
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                }
                
            }
            
        }
        .navigationTitle(category.name)
        
        .sheet(isPresented: $showingAddItem) {
            
            AddMenuItemView { newItem in
                
                var updated = items
                updated.append(newItem)
                viewModel.setItems(updated, for: category)
                
            }
            
        }
        
        .sheet(item: $editingItem) { item in
            
            AddMenuItemView(item: item) { updatedItem in
                
                var updated = items
                
                if let index = updated.firstIndex(where: { $0.id == item.id }) {
                    updated[index] = updatedItem
                }
                
                viewModel.setItems(updated, for: category)
                
            }
            
        }
        
        .toolbar {
            
            Button("Edit") {
                // we'll wire this up later
            }
            
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {

        var updated = items
        updated.move(fromOffsets: source, toOffset: destination)
        viewModel.setItems(updated, for: category)

    }

    private func deleteItems(at offsets: IndexSet) {

        var updated = items
        updated.remove(atOffsets: offsets)
        viewModel.setItems(updated, for: category)

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
