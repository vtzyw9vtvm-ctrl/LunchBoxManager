import SwiftUI

struct ModifierGroupSelector: View {

    @Binding var selectedGroups: [UUID]

    @Bindable var manager: ModifierManager

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Modifier Groups")
                .font(.title3.bold())

            ForEach(manager.groups) { group in

                VStack(alignment: .leading, spacing: 10) {

                    Toggle(
                        isOn: Binding(

                            get: {

                                selectedGroups.contains(group.id)

                            },

                            set: { isOn in

                                if isOn {

                                    if !selectedGroups.contains(group.id) {

                                        selectedGroups.append(group.id)

                                    }

                                } else {

                                    selectedGroups.removeAll {
                                        $0 == group.id
                                    }

                                }

                            }

                        )

                    ) {

                        Text(group.name)
                            .font(.headline)

                    }

                    VStack(alignment: .leading, spacing: 4) {

                        ForEach(group.modifiers) { modifier in

                            HStack {

                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(.secondary)

                                Text(modifier.name)

                                Spacer()

                                if modifier.price > 0 {

                                    Text("+$\(modifier.price, specifier: "%.2f")")
                                        .foregroundStyle(.orange)

                                }

                            }

                        }

                    }
                    .padding(.leading, 28)

                    Divider()

                }

            }

        }

        .padding()

    }

}

#Preview {

    @Previewable @State var selected: [UUID] = []

    ModifierGroupSelector(
        selectedGroups: $selected,
        manager: ModifierManager()
    )

}
