import Foundation

/// Represents a food or drink item included in a lunch order.
struct MenuItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var category: String
    var variants: [String]
    var quantity: Int
    var notes: String?
    var isHot: Bool
    var isCold: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        variants: [String] = [],
        quantity: Int = 1,
        notes: String? = nil,
        isHot: Bool = false,
        isCold: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.variants = variants
        self.quantity = quantity
        self.notes = notes
        self.isHot = isHot
        self.isCold = isCold
    }
}
