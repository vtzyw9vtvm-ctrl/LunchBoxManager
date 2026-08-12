import Foundation

/// Represents a class within a school (e.g. Prep A, 3B, 6A).
struct SchoolClass: Identifiable, Codable, Hashable, Sendable {

    let id: UUID

    /// Display name, e.g. "Prep A", "1B", "3A"
    var name: String

    /// The school this class belongs to.
    var schoolID: UUID

    /// Whether this class is currently active.
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        schoolID: UUID,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.schoolID = schoolID
        self.isActive = isActive
    }
}
