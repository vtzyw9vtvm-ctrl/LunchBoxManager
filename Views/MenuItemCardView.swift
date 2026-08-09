import SwiftUI

struct MenuItemCardView: View {

    let item: LunchMenuItem
    var isSelected: Bool = false

    var onDuplicate: (() -> Void)? = nil
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {

        HStack(spacing: 18) {

            Group {

                if let image = ImageStorage.shared.loadImage(named: item.imageName) {

                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()

                } else {

                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                }

            }
            .frame(width: 92, height: 92)
            .background(Color(.quaternarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {

                Text(item.name)
                    .font(.headline)

                Text(item.description)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {

                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)

                    Spacer()

                    Text("Cost $\(item.costPrice, specifier: "%.2f")")
                        .foregroundStyle(.secondary)

                    Text("Profit $\(item.price - item.costPrice, specifier: "%.2f")")
                        .foregroundStyle(.green)

                }

            }

            Spacer()

            if item.isActive {

                Text("ACTIVE")
                    .font(.caption.bold())
                    .foregroundStyle(.green)

            }

        }
        .padding(16)

        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isSelected
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear
                )
        )

        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15))
        )

        .contentShape(Rectangle())

        .contextMenu {


                Button {
                    onDuplicate?()
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }

                Divider()

                Button {
                    onMoveUp?()
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }

                Button {
                    onMoveDown?()
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }

            }

        .animation(.easeInOut(duration: 0.18), value: isSelected)

    }

}
