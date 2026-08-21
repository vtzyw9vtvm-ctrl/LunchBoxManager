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

    var imageName: String = ""

    var lastEdited = Date()

    var modifierGroups: [UUID] = []

    // MARK: - Production / Labels

    /// Included in the normal production/hot-label workflow.
    var isHot: Bool = true

    /// Also requires a separate cold-item label.
    var isCold: Bool = false
}
