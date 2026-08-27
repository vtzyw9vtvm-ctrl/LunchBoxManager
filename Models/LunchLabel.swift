import Foundation

/// Represents one thermal label for a student's lunch.
struct LunchLabel: Identifiable, Hashable {

    let id: UUID

    var orderNumber: String
    var schoolName: String
    var className: String
    var studentName: String

    /// Food allergy information supplied by the parent.
    /// Empty when no allergy has been entered.
    var foodAllergies: String

    var items: [MenuItem]

    init(
        id: UUID = UUID(),
        orderNumber: String,
        schoolName: String,
        className: String,
        studentName: String,
        foodAllergies: String = "",
        items: [MenuItem]
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.schoolName = schoolName
        self.className = className
        self.studentName = studentName
        self.foodAllergies = foodAllergies
        self.items = items
    }
}
