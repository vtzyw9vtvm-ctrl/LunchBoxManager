import Foundation

/// Represents a single data import attempt and its basic outcome.
struct ImportSession: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var fileName: String
    var importedAt: Date
    var importedOrderCount: Int
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        fileName: String,
        importedAt: Date = Date(),
        importedOrderCount: Int = 0,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.importedAt = importedAt
        self.importedOrderCount = importedOrderCount
        self.errorMessage = errorMessage
    }
}
