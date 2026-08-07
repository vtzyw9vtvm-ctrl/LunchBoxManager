import Foundation

struct Modifier: Identifiable, Codable, Hashable {

    var id = UUID()

    var name: String

    var price: Double = 0

    var isDefault: Bool = false

    var isAvailable: Bool = true

}
