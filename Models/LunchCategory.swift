import Foundation

struct LunchCategory: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String

    static let defaults: [LunchCategory] = [
        LunchCategory(
            name: "Hot Food",
            icon: "🍔"
        ),

        LunchCategory(
            name: "Sandwiches",
            icon: "🥪"
        ),

        LunchCategory(
            name: "Snacks",
            icon: "🍪"
        ),

        LunchCategory(
            name: "Drinks",
            icon: "🥤"
        )
    ]
}
