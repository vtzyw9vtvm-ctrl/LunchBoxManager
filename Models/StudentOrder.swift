import Foundation

/// Represents one student's lunch within a parent order.
struct StudentOrder: Identifiable, Codable, Hashable, Sendable {

    let id: UUID

    var student: Student
    var schoolClass: SchoolClass?
    var items: [MenuItem]

    /// Records whether this student's hot label has been printed.
    var hotLabelPrinted = false

    /// Records whether this student's cold label has been printed.
    var coldLabelPrinted = false

    init(
        id: UUID = UUID(),
        student: Student,
        schoolClass: SchoolClass? = nil,
        items: [MenuItem],
        hotLabelPrinted: Bool = false,
        coldLabelPrinted: Bool = false
    ) {
        self.id = id
        self.student = student
        self.schoolClass = schoolClass
        self.items = items
        self.hotLabelPrinted = hotLabelPrinted
        self.coldLabelPrinted = coldLabelPrinted
    }
}
