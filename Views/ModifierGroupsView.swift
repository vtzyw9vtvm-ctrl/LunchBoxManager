import SwiftUI

struct ModifierGroupsView: View {

    @State private var manager = ModifierManager()

    @State private var showingAddGroup = false
    @State private var newGroupName = ""

    var body: some View {

        NavigationStack {

            List {

                ForEach(manager.groups) { group in

                    Section(group.name) {

                        ForEach(group.modifiers) { modifier in

                            HStack {

                                Text(modifier.name)

                                Spacer()

                                if modifier.price > 0 {

                                    Text("+$\(modifier.price, specifier: "%.2f")")
                                        .foregroundStyle(.orange)

                                } else {

                                    Text("Free")
                                        .foregroundStyle(.secondary)

                                }

                            }

                        }

                    }

                }

            }
            .navigationTitle("Modifier Groups")

            .toolbar {

                ToolbarItem {

                    Button {

                        newGroupName = ""
                        showingAddGroup = true

                    } label: {

                        Label("New Group", systemImage: "plus")

                    }

                }

            }

            .sheet(isPresented: $showingAddGroup) {

                NavigationStack {

                    Form {

                        TextField(
                            "Group Name",
                            text: $newGroupName
                        )

                    }

                    .navigationTitle("New Modifier Group")

                    .toolbar {

                        ToolbarItem(placement: .cancellationAction) {

                            Button("Cancel") {

                                showingAddGroup = false

                            }

                        }

                        ToolbarItem(placement: .confirmationAction) {

                            Button("Add") {

                                manager.groups.append(
                                    ModifierGroup(
                                        name: newGroupName
                                    )
                                )

                                showingAddGroup = false

                            }
                            .disabled(newGroupName.isEmpty)

                        }

                    }

                }

            }

        }

    }

}

#Preview {

    ModifierGroupsView()

}
