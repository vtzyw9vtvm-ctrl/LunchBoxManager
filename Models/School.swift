import Foundation

/// Represents a school participating in the lunch ordering system.
struct School: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var shortName: String

    init(
        id: UUID = UUID(),
        name: String,
        shortName: String
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
    }
}
