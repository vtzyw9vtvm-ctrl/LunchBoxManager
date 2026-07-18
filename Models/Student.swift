import Foundation

/// Represents a student who can receive school lunch orders.
struct Student: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var firstName: String
    var lastName: String
    var classID: UUID?
    var dietaryNotes: String?

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        classID: UUID? = nil,
        dietaryNotes: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.classID = classID
        self.dietaryNotes = dietaryNotes
    }
}
