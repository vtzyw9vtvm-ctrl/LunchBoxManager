import Foundation

/// Represents a student who can place or receive lunch orders.
struct Student: Identifiable, Codable, Hashable, Sendable {

    let id: UUID

    var firstName: String
    var lastName: String

    var classID: UUID?

    var allergies = ""
    var notes = ""

    var isActive = true

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        classID: UUID? = nil,
        allergies: String = "",
        notes: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.classID = classID
        self.allergies = allergies
        self.notes = notes
        self.isActive = isActive
    }
}
