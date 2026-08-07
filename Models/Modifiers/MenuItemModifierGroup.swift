import Foundation

struct MenuItemModifierGroup: Identifiable, Codable, Hashable {

    var id = UUID()

    var groupID: UUID

    var displayOrder: Int = 0

    var isRequired: Bool = false

}
