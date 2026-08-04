import SwiftUI

struct MenuItemCardView: View {

    let item: LunchMenuItem

    var body: some View {

        HStack(spacing: 16) {

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.orange)
                )

            VStack(alignment: .leading, spacing: 6) {

                Text(item.name)
                    .font(.headline)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text("$\(item.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MenuItemCardView(
        item: LunchMenuItem(
            name: "Chicken Burger",
            description: "Crumbed chicken, lettuce and mayo",
            price: 10.50,
            imageName: ""
        )
    )
}
