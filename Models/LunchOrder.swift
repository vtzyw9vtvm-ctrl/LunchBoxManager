import Foundation

/// Represents a lunch order placed for a student on a specific date.
struct LunchOrder: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var studentID: UUID
    var orderDate: Date
    var menuItemIDs: [UUID]
    var notes: String?

    init(
        id: UUID = UUID(),
        studentID: UUID,
        orderDate: Date,
        menuItemIDs: [UUID],
        notes: String? = nil
    ) {
        self.id = id
        self.studentID = studentID
        self.orderDate = orderDate
        self.menuItemIDs = menuItemIDs
        self.notes = notes
    }
}
