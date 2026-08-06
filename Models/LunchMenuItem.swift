import Foundation

struct LunchMenuItem: Identifiable, Hashable, Codable {

    var id: UUID
    var name: String
    var description: String

    var category: String

    var price: Double
    var costPrice: Double

    var gstIncluded: Bool
    var isActive: Bool
    var isFeatured: Bool

    var imageName: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: String = "",
        price: Double,
        costPrice: Double = 0,
        gstIncluded: Bool = true,
        isActive: Bool = true,
        isFeatured: Bool = false,
        imageName: String
    ) {

        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.price = price
        self.costPrice = costPrice
        self.gstIncluded = gstIncluded
        self.isActive = isActive
        self.isFeatured = isFeatured
        self.imageName = imageName

    }

}
