import SwiftUI

struct ModifierWorkspaceView: View {

    @State private var manager = ModifierManager()

    @State private var selectedGroupID: UUID?
    @State private var selectedModifierID: UUID?

    private var selectedGroup: ModifierGroup? {

        guard let id = selectedGroupID else {
            return nil
        }

        return manager.groups.first { $0.id == id }

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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        
                        Text(group.name)
                            .font(.headline)
                        
                        Text("\(group.modifiers.count) modifiers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                    }
                    .tag(group.id)
                    
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
            .frame(minWidth: 520,
                   maxWidth: .infinity)
            
            // MARK: Inspector
            
            Group {
                
                if
                    let group = selectedGroup,
                    let modifierID = selectedModifierID,
                    let groupIndex = manager.groups.firstIndex(where: { $0.id == group.id }),
                    let modifierIndex = manager.groups[groupIndex].modifiers.firstIndex(where: { $0.id == modifierID })
                {
                    
                    ModifierInspector(
                        
                        modifier: Binding(
                            
                            get: {
                                
                                manager.groups[groupIndex].modifiers[modifierIndex]
                                
                            },
                            
                            set: { updated in
                                
                                manager.groups[groupIndex].modifiers[modifierIndex] = updated
                                
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
            .frame(width: 420)
            
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
        
        .navigationTitle("Modifier Groups")
        
        .onAppear {

            guard selectedGroupID == nil else { return }

            guard let firstGroup = manager.groups.first else { return }

            selectedGroupID = firstGroup.id

            if let first = firstGroup.modifiers.first {

                selectedModifierID = first.id

            } else {

                let modifier = manager.addModifier(to: firstGroup)

                selectedModifierID = modifier.id

            }

        }
        
        .onChange(of: selectedGroupID) {
            
            guard let group = selectedGroup else { return }
            
            if let first = manager.groups
                .first(where: { $0.id == group.id })?
                .modifiers
                .first {
                
                selectedModifierID = first.id
                
            } else {
                
                let modifier = manager.addModifier(to: group)
                
                selectedModifierID = modifier.id
                
            }
            
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
