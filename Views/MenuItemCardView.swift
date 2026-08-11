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

                HStack {

                    Text(item.name)
                        .font(.headline)

                    if item.isFeatured {

                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)

                    }

                    Spacer()

                    if item.isSoldOut {

                        Text("SOLD OUT")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)

                    } else if item.isActive {

                        Text("ACTIVE")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)

                    }

                }

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

                    let profit = item.price - item.costPrice
                    let margin = item.price > 0 ? (profit / item.price) * 100 : 0

                    VStack(alignment: .trailing, spacing: 2) {

                        Text("Profit $\(profit, specifier: "%.2f")")

                        Text("\(margin, specifier: "%.0f")%")
                            .font(.caption2)

                    }
                    .foregroundStyle(
                        profit < 0 ? .red :
                        profit < 2 ? .orange :
                        .green
                    )

                }

            }

            VStack {

                DragHandle()

                Spacer()

            }
            .frame(width: 28)

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

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }

        }

        .animation(.easeInOut(duration: 0.18), value: isSelected)

    }

}
