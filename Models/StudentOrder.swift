import Foundation

/// Represents one student's portion of a shared Wix lunch order.
struct StudentOrder: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var student: Student
    var schoolClass: SchoolClass?
    var items: [MenuItem]

    init(
        id: UUID = UUID(),
        student: Student,
        schoolClass: SchoolClass? = nil,
        items: [MenuItem]
    ) {
        self.id = id
        self.student = student
        self.schoolClass = schoolClass
        self.items = items
    }
}
