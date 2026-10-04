import SwiftUI

struct CafeMenuItemInspector: View {

    @Binding var item: LunchMenuItem

    @State private var modifierManager = CafeModifierManager()

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(
                    item.name.isEmpty
                    ? "New Menu Item"
                    : item.name
                )
                .font(.largeTitle.bold())

                Divider()

                // MARK: - Photo

                SectionCard("Photo") {

                    CafePhotoPickerCard(
                        imageName: $item.imageName,
                        imageURL: $item.imageURL
                    )
                }

                // MARK: - Details

                SectionCard("Details") {

                    TextField(
                        "Item Name",
                        text: $item.name
                    )
                    .textFieldStyle(.roundedBorder)

                    TextField(
                        "Description",
                        text: $item.description,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                    TextField(
                        "Category",
                        text: $item.category
                    )
                    .textFieldStyle(.roundedBorder)
                }

                // MARK: - Pricing

                SectionCard("Pricing") {

                    HStack {

                        Text("Sell Price")

                        Spacer()

                        TextField(
                            "",
                            value: $item.price,
                            format:
                                .number
                                .precision(
                                    .fractionLength(2)
                                )
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                    }

                    HStack {

                        Text("Cost Price")

                        Spacer()

                        TextField(
                            "",
                            value: $item.costPrice,
                            format:
                                .number
                                .precision(
                                    .fractionLength(2)
                                )
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                    }

                    Toggle(
                        "GST Included",
                        isOn: $item.gstIncluded
                    )
                    }

                    // MARK: - Multi-Buy Pricing

                    SectionCard("Multi-Buy Pricing") {

                        Toggle(
                            "Enable Multi-Buy Deal",
                            isOn: $item.multiBuyEnabled
                        )

                        if item.multiBuyEnabled {

                            HStack {

                                Text("Buy")

                                Spacer()

                                TextField(
                                    "",
                                    value: $item.multiBuyQuantity,
                                    format: .number
                                )
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            }

                            HStack {

                                Text("Deal Price")

                                Spacer()

                                Text("$")

                                TextField(
                                    "",
                                    value: $item.multiBuyPrice,
                                    format:
                                        .number
                                        .precision(
                                            .fractionLength(2)
                                        )
                                )
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                            }

                            if item.multiBuyQuantity > 0 &&
                                item.multiBuyPrice > 0 {

                                Text(
                                    "\(item.multiBuyQuantity) for $\(item.multiBuyPrice, specifier: "%.2f")"
                                )
                                .font(.headline)
                                .foregroundStyle(.green)
                            }

                            Text(
                                "The deal applies to the combined quantity of this item, including different modifier flavours."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // MARK: - Modifier Groups

                SectionCard("Modifier Groups") {

                    CafeModifierGroupSelector(
                        selectedGroups:
                            $item.modifierGroups,
                        manager:
                            modifierManager
                    )
                }

                // MARK: - Dietary Information

                SectionCard("Dietary Information") {

                    Toggle(
                        "Gluten Free",
                        isOn: $item.isGlutenFree
                    )

                    Toggle(
                        "Vegan",
                        isOn: $item.isVegan
                    )

                    Toggle(
                        "Vegetarian",
                        isOn: $item.isVegetarian
                    )

                    Toggle(
                        "Halal",
                        isOn: $item.isHalal
                    )

                    Text(
                        "Select all that apply. These will be shown to customers on the Espresso Cafe menu."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Options

                SectionCard("Options") {

                    Toggle(
                        "Active",
                        isOn: $item.isActive
                    )

                    Toggle(
                        "Sold Out",
                        isOn: $item.isSoldOut
                    )

                    Toggle(
                        "Featured",
                        isOn: $item.isFeatured
                    )

                    Divider()

                    Toggle(
                        "Allow Special Instructions",
                        isOn: $item.allowNotes
                    )

                    Text(
                        "Turn this on if customers are allowed to enter special instructions for this item."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Divider()

                    HStack {

                        Text("Last Edited")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(
                            item.lastEdited,
                            style: .date
                        )
                    }
                }
            }
            .padding(24)
        }
    }
}

#Preview {

    @Previewable
    @State var item = LunchMenuItem(
        name: "Chicken Burger",
        description:
            "Crumbed chicken, lettuce & mayo",
        price: 14.50
    )

    CafeMenuItemInspector(
        item: $item
    )
}
