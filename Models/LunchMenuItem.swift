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
    // NEW
    var modifierGroups: [UUID] = []

}
