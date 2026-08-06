import SwiftUI
import AppKit

struct MenuItemCardView: View {

    let item: LunchMenuItem

    var body: some View {

        HStack(spacing: 16) {

            if let image = ImageStorage.shared.loadImage(named: item.imageName) {

                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

            } else {

                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    )

            }

            VStack(alignment: .leading, spacing: 6) {

                HStack {

                    Text(item.name)
                        .font(.headline)

                    if item.isFeatured {

                        Label("", systemImage: "star.fill")
                            .foregroundStyle(.yellow)

                    }

                    Spacer()

                    if item.isActive {

                        Text("ACTIVE")
                            .font(.caption.bold())
                            .foregroundStyle(.green)

                    } else {

                        Text("HIDDEN")
                            .font(.caption.bold())
                            .foregroundStyle(.red)

                    }

                }

                Text(item.description)
                    .foregroundStyle(.secondary)

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

        }
        .padding(.vertical, 8)

    }

}

#Preview {

    MenuItemCardView(
        item: LunchMenuItem(
            name: "Chicken Burger",
            description: "Crumbed chicken with lettuce and mayo",
            price: 10.50,
            costPrice: 4.10,
            isFeatured: true,
            imageName: "chicken_burger"
        )
    )

}
