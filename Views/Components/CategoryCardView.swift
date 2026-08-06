import SwiftUI

struct CategoryCardView: View {

    let category: LunchCategory

    private var featuredItem: LunchMenuItem? {

        category.items.first(where: { $0.isFeatured })
        ?? category.items.first

    }

    var body: some View {

        HStack(spacing: 18) {

            ZStack {

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.12))

                Text(category.icon)
                    .font(.system(size: 38))

            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {

                Text(category.name)
                    .font(.title3.bold())

                Text("\(category.items.count) menu item\(category.items.count == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)

                if let featuredItem {

                    Text("Featured • \(featuredItem.name)")
                        .font(.caption)
                        .foregroundStyle(.orange)

                }

            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.title3)
                .foregroundStyle(.tertiary)

        }
        .padding(18)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 6)

    }

}

#Preview {

    CategoryCardView(
        category: LunchCategory(
            name: "Hot Food",
            icon: "🍔",
            items: [
                LunchMenuItem(
                    name: "Chicken Burger",
                    description: "",
                    category: "",
                    price: 10.50,
                    isFeatured: true,
                    imageName: ""
                )
            ]
        )
    )

}
