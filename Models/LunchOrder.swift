import Foundation

/// Represents a school lunch order placed through the parent ordering system.
struct LunchOrder: Identifiable, Codable, Hashable, Sendable {

    let id: UUID

    /// Customer-facing order number.
    var orderNumber: String

    /// School receiving the lunch order.
    var school: School

    /// One checkout may contain lunch orders for multiple children.
    var studentOrders: [StudentOrder]

    /// When the parent placed the order.
    var orderDate: Date

    /// The date the lunch is to be delivered to the school.
    var deliveryDate: Date

    /// Current processing state of the order.
    var status: LunchOrderStatus

    var notes: String?

    init(
        id: UUID = UUID(),
        orderNumber: String,
        school: School,
        studentOrders: [StudentOrder],
        orderDate: Date,
        deliveryDate: Date? = nil,
        status: LunchOrderStatus = .new,
        notes: String? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.school = school
        self.studentOrders = studentOrders
        self.orderDate = orderDate

        // Keeps existing/sample orders working while we transition
        // from the old system.
        self.deliveryDate = deliveryDate ?? orderDate

        self.status = status
        self.notes = notes
    }
}

enum LunchOrderStatus: String, Codable, CaseIterable, Hashable, Sendable {

    case new
    case processing
    case completed
    case cancelled

    var title: String {

        switch self {

        case .new:
            return "New"

        case .processing:
            return "Processing"

        case .completed:
            return "Completed"

        case .cancelled:
            return "Cancelled"

        }

    }

}
