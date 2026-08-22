import SwiftUI
import AppKit

struct AddMenuItemView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var sellPrice: String
    @State private var costPrice: String
    @State private var imageName: String
    @State private var imageURL = ""

    @State private var isActive: Bool
    @State private var isFeatured: Bool
    @State private var gstIncluded: Bool

    @State private var modifierGroups: [UUID]

    @State private var modifierManager = ModifierManager()

    let existingItem: LunchMenuItem?

    var onSave: (LunchMenuItem) -> Void

    init(
        item: LunchMenuItem? = nil,
        onSave: @escaping (LunchMenuItem) -> Void
    ) {

        existingItem = item
        self.onSave = onSave

        _name = State(initialValue: item?.name ?? "")
        _description = State(initialValue: item?.description ?? "")

        _sellPrice = State(
            initialValue: item == nil
            ? ""
            : String(format: "%.2f", item!.price)
        )

        _costPrice = State(
            initialValue: item == nil
            ? ""
            : String(format: "%.2f", item!.costPrice)
        )

        _imageName = State(initialValue: item?.imageName ?? "")
        _imageURL = State(initialValue: item?.imageURL ?? "")

        _isActive = State(initialValue: item?.isActive ?? true)
        _isFeatured = State(initialValue: item?.isFeatured ?? false)
        _gstIncluded = State(initialValue: item?.gstIncluded ?? true)

        _modifierGroups = State(initialValue: item?.modifierGroups ?? [])

    }

    var body: some View {

        NavigationStack {

            ScrollView {

                HStack(alignment: .top, spacing: 24) {

                    VStack(spacing: 24) {

                        SectionCard("Photo") {

                            PhotoPickerCard(
                                imageName: $imageName,
                                imageURL: $imageURL
                            )

                        }

                        SectionCard("Options") {

                            Toggle("Active", isOn: $isActive)

                            Toggle("Featured", isOn: $isFeatured)

                        }

                    }
                    .frame(width: 280)

                    VStack(spacing: 24) {

                        SectionCard("Details") {

                            TextField("Name", text: $name)
                                .textFieldStyle(.roundedBorder)

                            TextField("Description", text: $description)
                                .textFieldStyle(.roundedBorder)

                        }

                        SectionCard("Pricing") {

                            PriceEditor(
                                sellPrice: $sellPrice,
                                costPrice: $costPrice,
                                gstIncluded: $gstIncluded
                            )

                        }

                        SectionCard("Modifier Groups") {

                            ModifierGroupSelector(
                                selectedGroups: $modifierGroups,
                                manager: modifierManager
                            )

                        }

                    }

                }
                .padding(24)

            }

            .frame(minWidth: 900, minHeight: 720)

            .navigationTitle(
                existingItem == nil
                ? "Add Menu Item"
                : "Edit Menu Item"
            )

            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {

                        dismiss()

                    }

                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {

                        let item = LunchMenuItem(
                            id: existingItem?.id ?? UUID(),
                            name: name,
                            description: description,
                            category: existingItem?.category ?? "",
                            price: Double(sellPrice) ?? 0,
                            costPrice: Double(costPrice) ?? 0,
                            gstIncluded: gstIncluded,
                            isActive: isActive,
                            isFeatured: isFeatured,
                            imageName: imageName,
                            imageURL: imageURL,
                            modifierGroups: modifierGroups
                        )

                        onSave(item)
                        dismiss()
                    }
                }

            }

        }

    }

}

#Preview {

    AddMenuItemView { _ in }

}
