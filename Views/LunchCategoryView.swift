import SwiftUI

struct LunchCategoryView: View {

    let category: LunchCategory

    @State private var items: [LunchMenuItem] = [

        LunchMenuItem(
            name: "Bacon & Egg Roll",
            description: "Seeded brioche bun with bacon and egg",
            price: 8.50,
            imageName: "bacon_egg"
        ),

        LunchMenuItem(
            name: "Chicken Burger",
            description: "Crumbed chicken, lettuce and mayo",
            price: 10.50,
            imageName: "chicken_burger"
        ),

        LunchMenuItem(
            name: "Fish & Chips",
            description: "Battered fish with chips",
            price: 11.00,
            imageName: "fish_chips"
        ),

        LunchMenuItem(
            name: "Nuggets & Chips",
            description: "Six nuggets with chips",
            price: 8.00,
            imageName: "nuggets"
        )
    ]
    
    @State private var showingAddItem = false

    var body: some View {
        List {

            Section {

                ForEach(items) { item in

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
                                .lineLimit(2)

                            Text("$\(item.price, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .padding(.vertical, 8)
                }
                .onMove { from, to in
                    moveItems(from: from, to: to)
                }

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
                items.append(newItem)
            }

        }
        .toolbar { }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    NavigationStack {
        LunchCategoryView(
            category: LunchCategory(
                name: "Hot Food",
                icon: "🍔"
            )
        )
    }
}
