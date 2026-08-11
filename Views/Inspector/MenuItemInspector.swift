import SwiftUI

struct MenuItemInspector: View {

    @Binding var item: LunchMenuItem

    @State private var modifierManager = ModifierManager()

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(item.name.isEmpty ? "New Menu Item" : item.name)
                    .font(.largeTitle.bold())

                Divider()

                // MARK: Photo

                SectionCard("Photo") {

                    PhotoPickerCard(imageName: $item.imageName)

                }

                // MARK: Details

                SectionCard("Details") {

                    TextField("Item Name", text: $item.name)
                        .textFieldStyle(.roundedBorder)

                    TextField(
                        "Description",
                        text: $item.description,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                    TextField("Category", text: $item.category)
                        .textFieldStyle(.roundedBorder)

                }

                // MARK: Pricing

                SectionCard("Pricing") {

                    HStack {

                        Text("Sell Price")

                        Spacer()

                        TextField(
                            "",
                            value: $item.price,
                            format: .number.precision(.fractionLength(2))
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
                            format: .number.precision(.fractionLength(2))
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)

                    }

                    Toggle("GST Included", isOn: $item.gstIncluded)

                }

                // MARK: Modifier Groups

                SectionCard("Modifier Groups") {

                    ModifierGroupSelector(
                        selectedGroups: $item.modifierGroups,
                        manager: modifierManager
                    )

                }

                // MARK: Options

                SectionCard("Options") {

                    Toggle("Active", isOn: $item.isActive)

                    Toggle("Sold Out", isOn: $item.isSoldOut)

                    Toggle("Featured", isOn: $item.isFeatured)
                    
                    Divider()

                    HStack {

                        Text("Last Edited")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(item.lastEdited, style: .date)

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
        description: "Crumbed chicken, lettuce & mayo",
        price: 14.50
    )

    MenuItemInspector(item: $item)

}
