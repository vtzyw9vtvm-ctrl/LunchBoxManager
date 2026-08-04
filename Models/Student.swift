import Foundation

/// Represents a student who can place or receive lunch orders.
struct Student: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var firstName: String
    var lastName: String
    var fullName: String
    var classID: UUID?

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        fullName: String,
        classID: UUID? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.classID = classID
    }
}
