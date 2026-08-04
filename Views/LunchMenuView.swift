import SwiftUI

struct LunchMenuView: View {

    let categories: [LunchCategory] = [
        LunchCategory(name: "Hot Food", icon: "🍔"),
        LunchCategory(name: "Sandwiches", icon: "🥪"),
        LunchCategory(name: "Snacks", icon: "🍪"),
        LunchCategory(name: "Drinks", icon: "🥤")
    ]

    var body: some View {
        NavigationStack {
            List(categories) { category in
                NavigationLink {
                    LunchCategoryView(category: category)
                } label: {
                    HStack(spacing: 16) {
                        Text(category.icon)
                            .font(.title2)

                        Text(category.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Lunch Menu")
        }
    }
}

#Preview {
    LunchMenuView()
}
