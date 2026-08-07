import SwiftUI

struct MenuManagerView: View {

    @State private var menuManager = MenuViewModel()

    @State private var selectedCategory: LunchCategory?
    @State private var selectedItem: LunchMenuItem?

    var body: some View {

        NavigationSplitView {

            List(menuManager.categories,
                 selection: $selectedCategory) { category in

                HStack(spacing: 12) {

                    Text(category.icon)
                        .font(.title3)

                    VStack(alignment: .leading) {

                        Text(category.name)

                        Text("\(category.items.count) item\(category.items.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    }

                }
                .tag(category)

            }
            .navigationTitle("Menu")

        } content: {

            if let selectedCategory {

                List(
                    menuManager.items(for: selectedCategory),
                    selection: $selectedItem
                ) { item in

                    HStack(spacing: 14) {

                        if let image = ImageStorage.shared.loadImage(named: item.imageName) {

                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                        } else {

                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray.opacity(0.15))
                                .frame(width: 44, height: 44)

                        }

                        VStack(alignment: .leading) {

                            Text(item.name)
                                .font(.headline)

                            Text("$\(item.price, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                        }

                    }
                    .padding(.vertical, 4)
                    .tag(item)

                }

                .navigationTitle(selectedCategory.name)

            } else {

                ContentUnavailableView(
                    "Select a Category",
                    systemImage: "folder",
                    description: Text("Choose a category from the left.")
                )

            }

        } detail: {

            if let selectedItem {

                ScrollView {

                    VStack(alignment: .leading, spacing: 24) {

                        Text(selectedItem.name)
                            .font(.largeTitle.bold())

                        Divider()

                        Group {

                            Text("Description")
                                .font(.headline)

                            Text(selectedItem.description)

                        }

                        Divider()

                        Group {

                            Text("Sell Price")
                                .font(.headline)

                            Text("$\(selectedItem.price, specifier: "%.2f")")

                        }

                        Divider()

                        Group {

                            Text("Cost Price")
                                .font(.headline)

                            Text("$\(selectedItem.costPrice, specifier: "%.2f")")

                        }

                        Divider()

                        Group {

                            Text("Modifier Groups")
                                .font(.headline)

                            Text("\(selectedItem.modifierGroups.count) attached")

                        }

                        Divider()

                        Toggle("Active",
                               isOn: .constant(selectedItem.isActive))

                        Toggle("Featured",
                               isOn: .constant(selectedItem.isFeatured))

                    }

                    .padding(24)

                }

                .navigationTitle("Inspector")

            } else {

                ContentUnavailableView(
                    "Select a Menu Item",
                    systemImage: "fork.knife",
                    description: Text("Choose a menu item to edit.")
                )

            }

        }
        .navigationSplitViewColumnWidth(min: 230, ideal: 260)

    }

}

#Preview {

    MenuManagerView()

}
