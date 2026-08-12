import Foundation

/// Represents a school participating in the lunch ordering system.
struct School: Identifiable, Codable, Hashable, Sendable {

    let id: UUID

    var name: String
    var shortName: String

    var isActive = true

    var orderCutoffTime = "8:30 AM"
    var deliveryTime = "12:30 PM"

    var notes = ""

    init(
        id: UUID = UUID(),
        name: String,
        shortName: String,
        isActive: Bool = true,
        orderCutoffTime: String = "8:30 AM",
        deliveryTime: String = "12:30 PM",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.isActive = isActive
        self.orderCutoffTime = orderCutoffTime
        self.deliveryTime = deliveryTime
        self.notes = notes
    }
}
