import Foundation

struct LunchMenuItem: Identifiable, Hashable {

    let id = UUID()

    var name: String
    var description: String
    var price: Double
    var imageName: String
}
