import SwiftUI

struct AddMenuItemView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var price: String

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
        _price = State(initialValue: item != nil ? String(format: "%.2f", item!.price) : "")
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Item") {

                    TextField("Name", text: $name)

                    TextField("Description", text: $description)

                    TextField("Price", text: $price)
                }
            }
            .navigationTitle(existingItem == nil ? "Add Item" : "Edit Item")
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {

                        let item = LunchMenuItem(
                            name: name,
                            description: description,
                            price: Double(price) ?? 0,
                            imageName: existingItem?.imageName ?? ""
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
