import SwiftUI

struct ModifierWorkspaceView: View {

    @State private var manager = ModifierManager()

    @State private var selectedGroup: ModifierGroup?
    @State private var selectedModifierID: UUID?

    var body: some View {

        HSplitView {

            // MARK: Groups

            VStack(spacing: 0) {

                toolbar(
                    title: "Modifier Groups",
                    systemImage: "plus"
                ) {

                    // TODO: Add Group

                }

                Divider()

                List(manager.groups,
                     selection: $selectedGroup) { group in

                    VStack(alignment: .leading, spacing: 2) {

                        Text(group.name)
                            .font(.headline)

                        Text("\(group.modifiers.count) modifiers")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    }
                    .tag(group)

                }

            }
            .frame(minWidth: 260,
                   idealWidth: 280,
                   maxWidth: 320)

            // MARK: Modifiers

            VStack(spacing: 0) {

                toolbar(
                    title: selectedGroup?.name ?? "Modifiers",
                    systemImage: "plus"
                ) {

                    // TODO: Add Modifier

                }

                Divider()

                if let group = selectedGroup {

                    List {

                        ForEach(group.modifiers) { modifier in

                            HStack {

                                VStack(alignment: .leading, spacing: 4) {

                                    Text(modifier.name)
                                        .font(.headline)

                                    Text("$\(modifier.price, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                }

                                Spacer()

                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {

                                selectedModifierID = modifier.id

                            }

                        }

                    }
                    .listStyle(.plain)

                } else {

                    ContentUnavailableView(
                        "Select Modifier Group",
                        systemImage: "slider.horizontal.3"
                    )

                }

            }
            .frame(minWidth: 520,
                   maxWidth: .infinity)

            // MARK: Inspector

            Group {

                if
                    let group = selectedGroup,
                    let id = selectedModifierID,
                    let modifier = group.modifiers.first(where: { $0.id == id })
                {

                    ScrollView {

                        VStack(alignment: .leading, spacing: 24) {

                            Text(modifier.name)
                                .font(.largeTitle.bold())

                            Divider()

                            VStack(alignment: .leading) {

                                Text("Name")
                                    .font(.headline)

                                Text(modifier.name)

                            }

                            Divider()

                            VStack(alignment: .leading) {

                                Text("Price")
                                    .font(.headline)

                                Text("$\(modifier.price, specifier: "%.2f")")

                            }

                            Spacer()

                        }
                        .padding(24)

                    }

                } else {

                    ContentUnavailableView(
                        "Select Modifier",
                        systemImage: "slider.horizontal.3"
                    )

                }

            }
            .frame(width: 420)

        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)

        .navigationTitle("Modifier Groups")

        .onAppear {

            guard selectedGroup == nil else { return }

            if let group = manager.groups.first {

                selectedGroup = group

                if let firstModifier = group.modifiers.first {

                    selectedModifierID = firstModifier.id

                }

            }

        }

        .onChange(of: selectedGroup) {

            guard let group = selectedGroup else { return }

            selectedModifierID = group.modifiers.first?.id

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

    ModifierWorkspaceView()

}
