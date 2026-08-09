import SwiftUI

struct ModifierGroupInspector: View {

    @Binding var group: ModifierGroup

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 28) {

                Text(group.name)
                    .font(.largeTitle.bold())

                Divider()

                // MARK: Details

                GroupBox("Details") {

                    VStack(spacing: 16) {

                        TextField(
                            "Group Name",
                            text: $group.name
                        )

                    }
                    .padding(.top, 8)

                }

                // MARK: Rules

                GroupBox("Rules") {

                    VStack(spacing: 18) {

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
