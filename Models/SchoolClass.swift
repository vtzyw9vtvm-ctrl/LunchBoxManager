import Foundation

/// Represents a school class or homeroom group.
struct SchoolClass: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var teacherName: String?

    init(
        id: UUID = UUID(),
        name: String,
        teacherName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.teacherName = teacherName
    }
}
