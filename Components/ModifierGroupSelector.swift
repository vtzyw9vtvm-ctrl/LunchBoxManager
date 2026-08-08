import SwiftUI

struct ModifierGroupSelector: View {

    @Binding var selectedGroups: [UUID]

    @Bindable var manager: ModifierManager

    var body: some View {

        VStack(spacing: 12) {

            ForEach(manager.groups) { group in

                Button {

                    toggle(group)

                } label: {

                    HStack(spacing: 16) {

                        Image(systemName:
                                selectedGroups.contains(group.id)
                              ? "checkmark.circle.fill"
                              : "circle")
                        .font(.title2)
                        .foregroundColor(
                            selectedGroups.contains(group.id)
                            ? .accentColor
                            : .secondary
                        )

                        VStack(alignment: .leading, spacing: 4) {

                            Text(group.name)
                                .font(.headline)

                            Text("\(group.modifiers.count) modifier\(group.modifiers.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)

                    }
                    .padding()

                    .background(

                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                selectedGroups.contains(group.id)
                                ? Color.accentColor.opacity(0.12)
                                : Color.gray.opacity(0.06)
                            )

                    )

                }
                .buttonStyle(.plain)

            }

        }

    }

    private func toggle(_ group: ModifierGroup) {

        if let index = selectedGroups.firstIndex(of: group.id) {

            selectedGroups.remove(at: index)

        } else {

            selectedGroups.append(group.id)

        }

    }

}

#Preview {

    @Previewable
    @State var selected: [UUID] = []

    ModifierGroupSelector(
        selectedGroups: $selected,
        manager: ModifierManager()
    )

}
