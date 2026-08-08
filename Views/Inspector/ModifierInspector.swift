import SwiftUI

struct ModifierInspector: View {

    @Binding var modifier: Modifier

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 28) {

                // MARK: Header

                Text(modifier.name)
                    .font(.largeTitle.bold())

                Divider()

                // MARK: Details

                GroupBox("Details") {

                    VStack(spacing: 16) {

                        TextField(
                            "Modifier Name",
                            text: $modifier.name
                        )

                    }
                    .padding(.top, 8)

                }

                // MARK: Pricing

                GroupBox("Pricing") {

                    VStack(spacing: 16) {

                        HStack {

                            Text("Price")

                            Spacer()

                            TextField(
                                "0.00",
                                value: $modifier.price,
                                format: .number
                            )
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)

                        }

                    }
                    .padding(.top, 8)

                }

                // MARK: Status

                GroupBox("Status") {

                    Toggle("Active", isOn: .constant(true))

                }

                Spacer(minLength: 40)

            }
            .padding(24)

        }

    }

}

#Preview {

    ModifierInspector(
        modifier: .constant(
            Modifier(
                name: "Cheese",
                price: 1.00
            )
        )
    )

}
