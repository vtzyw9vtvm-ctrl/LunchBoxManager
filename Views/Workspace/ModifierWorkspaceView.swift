import SwiftUI

struct ModifierWorkspaceView: View {

    @State private var manager = ModifierManager()

    @State private var selectedGroupID: UUID?
    @State private var selectedModifierID: UUID?

    private var selectedGroup: ModifierGroup? {

        guard let id = selectedGroupID else {
            return nil
        }

        return manager.groups.first(where: { $0.id == id })

    }

    var body: some View {

        HSplitView {
            
            // MARK: Groups
            
            VStack(spacing: 0) {
                
                toolbar(
                    title: "Modifier Groups",
                    systemImage: "plus"
                ) {
                    
                    let group = manager.addGroup()
                    
                    selectedGroupID = group.id
                    selectedModifierID = group.modifiers.first?.id
                    
                }
                
                Divider()
                
                List(
                    manager.groups,
                    selection: $selectedGroupID
                ) { group in
                    
                    HStack {
                        
                        VStack(alignment: .leading, spacing: 2) {
                            
                            Text(group.name)
                                .font(.headline)
                            
                            Text("\(group.modifiers.count) modifiers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                        }
                        
                        Spacer()
                        
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    
                    .contextMenu {
                        
                        Button {
                            
                            var copy = group
                            copy.id = UUID()
                            copy.name += " Copy"
                            
                            manager.groups.append(copy)
                            
                        } label: {
                            
                            Label(
                                "Duplicate",
                                systemImage: "plus.square.on.square"
                            )
                            
                        }
                        
                        Divider()
                        
                        Button(
                            role: .destructive
                        ) {
                            
                            manager.deleteGroup(group)
                            
                            if let first = manager.groups.first {
                                
                                selectedGroupID = first.id
                                selectedModifierID = first.modifiers.first?.id
                                
                            } else {
                                
                                selectedGroupID = nil
                                selectedModifierID = nil
                                
                            }
                            
                        } label: {
                            
                            Label(
                                "Delete",
                                systemImage: "trash"
                            )
                            
                        }
                        
                    }
                    
                    .tag(group.id)
                    
                }
                
            }
            .frame(
                minWidth: 260,
                idealWidth: 280,
                maxWidth: 320
            )
            
            // MARK: Modifiers
            
            VStack(spacing: 0) {
                
                toolbar(
                    title: selectedGroup?.name ?? "Modifiers",
                    systemImage: "plus"
                ) {
                    
                    guard let group = selectedGroup else { return }
                    
                    let modifier = manager.addModifier(to: group)
                    
                    selectedModifierID = modifier.id
                    
                }
                
                Divider()
                
                if let group = selectedGroup {
                    
                    ScrollView {
                        
                        LazyVStack(spacing: 12) {
                            
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
                                .padding()
                                
                                .background(
                                    
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            selectedModifierID == modifier.id
                                            ? Color.accentColor.opacity(0.15)
                                            : Color.clear
                                        )
                                    
                                )
                                
                                .overlay(
                                    
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(.gray.opacity(0.15))
                                    
                                )
                                
                                .contentShape(Rectangle())
                                
                                .onTapGesture {
                                    
                                    selectedModifierID = modifier.id
                                    
                                }
                                
                                .contextMenu {
                                    
                                    Button {
                                        
                                        _ = manager.duplicateModifier(
                                            modifier,
                                            in: group
                                        )
                                        
                                    } label: {
                                        
                                        Label(
                                            "Duplicate",
                                            systemImage: "plus.square.on.square"
                                        )
                                        
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        
                                        manager.deleteModifier(
                                            modifier,
                                            from: group
                                        )
                                        
                                        if let currentGroup = manager.groups.first(where: { $0.id == group.id }) {
                                            
                                            selectedModifierID = currentGroup.modifiers.first?.id
                                            
                                        } else {
                                            
                                            selectedModifierID = nil
                                            
                                        }
                                        
                                    } label: {
                                        
                                        Label(
                                            "Delete",
                                            systemImage: "trash"
                                        )
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        .padding()
                        
                    }
                    
                } else {
                    
                    ContentUnavailableView(
                        "Select Modifier Group",
                        systemImage: "slider.horizontal.3"
                    )
                    
                }
                
            }
            .frame(
                minWidth: 520,
                maxWidth: .infinity
            )
            
            // MARK: Inspector
            
            Group {

                if let group = selectedGroup {

                    VStack(spacing: 0) {

                        CategoryInspector(

                            category: Binding(

                                get: {

                                    LunchCategory(
                                        id: group.id,
                                        name: group.name,
                                        icon: "slider.horizontal.3"
                                    )

                                },

                                set: { updated in

                                    var updatedGroup = group
                                    updatedGroup.name = updated.name

                                    manager.updateGroup(updatedGroup)

                                }

                            )

                        )

                        Divider()

                        if
                            let modifierID = selectedModifierID,
                            let currentGroup = manager.groups.first(where: { $0.id == group.id }),
                            let modifier = currentGroup.modifiers.first(where: { $0.id == modifierID })
                        {

                            ModifierInspector(

                                modifier: Binding(

                                    get: {

                                        modifier

                                    },

                                    set: { updated in

                                        manager.updateModifier(
                                            updated,
                                            in: currentGroup
                                        )

                                    }

                                )

                            )

                        } else {

                            ContentUnavailableView(
                                "Select Modifier",
                                systemImage: "slider.horizontal.3"
                            )

                        }

                    }

                } else {

                    ContentUnavailableView(
                        "Select Modifier Group",
                        systemImage: "slider.horizontal.3"
                    )

                }

            }
            .frame(width: 420)

        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )

        .navigationTitle("Modifier Groups")

        .onAppear {

            guard selectedGroupID == nil else { return }

            guard let firstGroup = manager.groups.first else { return }

            selectedGroupID = firstGroup.id
            selectedModifierID = firstGroup.modifiers.first?.id

        }

        .onChange(of: selectedGroupID) {

            guard
                let id = selectedGroupID,
                let group = manager.groups.first(where: { $0.id == id })
            else {

                selectedModifierID = nil
                return

            }

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
