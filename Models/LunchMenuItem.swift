import Foundation

struct LunchMenuItem: Identifiable, Codable, Hashable {

    var id = UUID()

    var name: String
    var description: String

    var category: String = ""

    var price: Double
    var costPrice: Double = 0

    var gstIncluded = true
    var isActive = true
    var isFeatured = false

    var imageName: String = ""

    // NEW
    var modifierGroups: [UUID] = []

}
