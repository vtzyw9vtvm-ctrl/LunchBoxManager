import Foundation

struct LunchMenuItem: Identifiable, Codable, Hashable {

    var id = UUID()
    var sortOrder: Int = 0
    var name: String
    var description: String
    var category: String = ""
    var price: Double
    var costPrice: Double = 0
    var gstIncluded = true
    var isActive = true
    var isSoldOut = false
    var isFeatured = false

    /// Allows the parent to enter special instructions for this item.
    var allowNotes: Bool = true

    var imageName: String = ""
    var imageURL: String = ""
    var lastEdited = Date()
    var modifierGroups: [UUID] = []

    // MARK: - Production / Labels

    /// Included in the normal production/hot-label workflow.
    var isHot: Bool = true

    /// Also requires a separate cold-item label.
    var isCold: Bool = false

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case sortOrder
        case name
        case description
        case category
        case price
        case costPrice
        case gstIncluded
        case isActive
        case isSoldOut
        case isFeatured
        case allowNotes
        case imageName
        case imageURL
        case lastEdited
        case modifierGroups
        case isHot
        case isCold
    }

    init(
        id: UUID = UUID(),
        sortOrder: Int = 0,
        name: String,
        description: String,
        category: String = "",
        price: Double,
        costPrice: Double = 0,
        gstIncluded: Bool = true,
        isActive: Bool = true,
        isSoldOut: Bool = false,
        isFeatured: Bool = false,
        allowNotes: Bool = true,
        imageName: String = "",
        imageURL: String = "",
        lastEdited: Date = Date(),
        modifierGroups: [UUID] = [],
        isHot: Bool = true,
        isCold: Bool = false
    ) {
        self.id = id
        self.sortOrder = sortOrder
        self.name = name
        self.description = description
        self.category = category
        self.price = price
        self.costPrice = costPrice
        self.gstIncluded = gstIncluded
        self.isActive = isActive
        self.isSoldOut = isSoldOut
        self.isFeatured = isFeatured
        self.allowNotes = allowNotes
        self.imageName = imageName
        self.imageURL = imageURL
        self.lastEdited = lastEdited
        self.modifierGroups = modifierGroups
        self.isHot = isHot
        self.isCold = isCold
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0
        costPrice = try container.decodeIfPresent(Double.self, forKey: .costPrice) ?? 0
        gstIncluded = try container.decodeIfPresent(Bool.self, forKey: .gstIncluded) ?? true
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isSoldOut = try container.decodeIfPresent(Bool.self, forKey: .isSoldOut) ?? false
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false

        // Older saved menus won't contain this field.
        allowNotes = try container.decodeIfPresent(Bool.self, forKey: .allowNotes) ?? true

        imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? ""
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL) ?? ""
        lastEdited = try container.decodeIfPresent(Date.self, forKey: .lastEdited) ?? Date()
        modifierGroups = try container.decodeIfPresent([UUID].self, forKey: .modifierGroups) ?? []
        isHot = try container.decodeIfPresent(Bool.self, forKey: .isHot) ?? true
        isCold = try container.decodeIfPresent(Bool.self, forKey: .isCold) ?? false
    }
}
