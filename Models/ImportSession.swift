import Foundation

/// Represents a single imported file and its summary counts.
struct ImportSession: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var filename: String
    var importDate: Date
    var totalOrders: Int
    var totalStudents: Int
    var totalClasses: Int
    var totalSchools: Int

    init(
        id: UUID = UUID(),
        filename: String,
        importDate: Date = Date(),
        totalOrders: Int = 0,
        totalStudents: Int = 0,
        totalClasses: Int = 0,
        totalSchools: Int = 0
    ) {
        self.id = id
        self.filename = filename
        self.importDate = importDate
        self.totalOrders = totalOrders
        self.totalStudents = totalStudents
        self.totalClasses = totalClasses
        self.totalSchools = totalSchools
    }
}
