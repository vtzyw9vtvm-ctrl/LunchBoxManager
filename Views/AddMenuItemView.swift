import SwiftUI

struct AddMenuItemView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var price = ""

    var onSave: (LunchMenuItem) -> Void

    var body: some View {

        NavigationStack {

            Form {

                Section("Item") {

                    TextField("Name", text: $name)

                    TextField("Description", text: $description)

                    TextField("Price", text: $price)
                }
            }
            .navigationTitle("Add Item")
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {

                        let newItem = LunchMenuItem(
                            name: name,
                            description: description,
                            price: Double(price) ?? 0,
                            imageName: ""
                        )

                        onSave(newItem)

                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {

    AddMenuItemView { _ in

    }
}
