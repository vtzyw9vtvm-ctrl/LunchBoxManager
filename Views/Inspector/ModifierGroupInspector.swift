import SwiftUI

struct ModifierGroupInspector: View {

    @Binding var group: ModifierGroup

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 28) {

                Text(group.name)
                    .font(.largeTitle.bold())

                Divider()

                // MARK: - Details

                GroupBox("Details") {

                    VStack(alignment: .leading, spacing: 16) {

                        VStack(alignment: .leading, spacing: 6) {

                            Text("Manager Name")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField(
                                "e.g. Burger Extras",
                                text: $group.name
                            )

                            Text(
                                "Only shown in LunchBox Manager."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {

                            Text("Parent App Name")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField(
                                "e.g. Extras",
                                text: $group.customerName
                            )

                            Text(
                                "This is the heading parents will see when ordering."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }

                // MARK: - Rules

                GroupBox("Rules") {

                    VStack(alignment: .leading, spacing: 18) {

                        HStack {

                            Text("Minimum Selections")

                            Spacer()

                            TextField(
                                "0",
                                value: $group.minimumSelections,
                                format: .number
                            )
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                        }

                        HStack {

                            Text("Maximum Selections")

                            Spacer()

                            TextField(
                                "99",
                                value: $group.maximumSelections,
                                format: .number
                            )
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                        }

                        Toggle(
                            "Display as Radio Buttons",
                            isOn: $group.useRadioButtons
                        )

                        Divider()

                        Toggle(
                            "Allow Modifier Quantities",
                            isOn: $group.allowQuantities
                        )

                        Text(
                            "Allows the customer to choose a separate quantity for modifiers in this group. For example, 3 Party Pies can have 1 Dipping Sauce instead of automatically charging for 3 sauces."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }

                Spacer(minLength: 40)
            }
            .padding(24)
        }
    }
}

#Preview {

    ModifierGroupInspector(
        group: .constant(
            ModifierGroup(
                name: "Extras"
            )
        )
    )
}
