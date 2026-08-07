import SwiftUI

struct MenuWorkspaceView: View {

    @State private var menuManager = MenuViewModel()

    @State private var selectedCategory: LunchCategory?
    @State private var selectedItemID: UUID?

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
                                    isSelected: selectedItemID == item.id
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

                } else {

                    ContentUnavailableView(
                        "Select Menu Item",
                        systemImage: "fork.knife"
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

            if let category = menuManager.categories.first {

                selectedCategory = category

                if let firstItem = menuManager.items(for: category).first {

                    selectedItemID = firstItem.id

                }

            }

        }

        .onChange(of: selectedCategory) {

            guard let category = selectedCategory else { return }

            selectedItemID = menuManager.items(for: category).first?.id

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
