import Foundation

/// Represents a class or year group within a school.
struct SchoolClass: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var yearLevel: String
    var schoolID: UUID

    init(
        id: UUID = UUID(),
        name: String,
        yearLevel: String,
        schoolID: UUID
    ) {
        self.id = id
        self.name = name
        self.yearLevel = yearLevel
        self.schoolID = schoolID
    }
}
