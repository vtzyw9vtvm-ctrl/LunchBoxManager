import Foundation

struct LunchCategory: Identifiable, Hashable {

    var id = UUID()
    var name: String
    var icon: String
    var items: [LunchMenuItem]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        items: [LunchMenuItem] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.items = items
    }

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
