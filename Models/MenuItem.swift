import Foundation

/// Represents an item available on the school lunch menu.
struct MenuItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var description: String?
    var price: Decimal
    var isAvailable: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        price: Decimal,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.isAvailable = isAvailable
    }
}
