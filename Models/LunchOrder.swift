import Foundation

/// Represents a Wix lunch order that may include meals for multiple students.
struct LunchOrder: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var orderNumber: String
    var school: School
    var studentOrders: [StudentOrder]
    var orderDate: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        orderNumber: String,
        school: School,
        studentOrders: [StudentOrder],
        orderDate: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.school = school
        self.studentOrders = studentOrders
        self.orderDate = orderDate
        self.notes = notes
    }
}
