import Foundation

struct LunchCategory: Identifiable, Hashable, Codable {

    var id = UUID()
    var sortOrder: Int = 0
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

}
