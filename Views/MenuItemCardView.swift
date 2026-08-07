import SwiftUI

struct MenuItemCardView: View {

    let item: LunchMenuItem
    var isSelected: Bool = false

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
                .fill(isSelected ? Color.accentColor : Color.clear)

        )
        .overlay(

            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15))

        )
        .animation(.easeInOut(duration: 0.18), value: isSelected)

    }

}
