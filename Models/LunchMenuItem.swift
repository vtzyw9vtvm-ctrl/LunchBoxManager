import Foundation

struct LunchMenuItem: Identifiable {

    let id = UUID()

    var name: String
    var description: String
    var price: Double
    var imageName: String
}
