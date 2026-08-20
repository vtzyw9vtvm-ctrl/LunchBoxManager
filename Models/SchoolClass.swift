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

    /// Days on which this class can receive school lunches.
    var lunchDays: Set<SchoolLunchDay>

    /// Controls the order in which classes are displayed.
    var sortOrder: Int


    init(
        id: UUID = UUID(),
        name: String,
        schoolID: UUID,
        isActive: Bool = true,
        lunchDays: Set<SchoolLunchDay> = Set(SchoolLunchDay.allCases),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.schoolID = schoolID
        self.isActive = isActive
        self.lunchDays = lunchDays
        self.sortOrder = sortOrder
    }


    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case schoolID
        case isActive
        case lunchDays
        case sortOrder
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(
            UUID.self,
            forKey: .id
        )

        name = try container.decode(
            String.self,
            forKey: .name
        )

        schoolID = try container.decode(
            UUID.self,
            forKey: .schoolID
        )

        isActive = try container.decodeIfPresent(
            Bool.self,
            forKey: .isActive
        ) ?? true

        // Existing classes saved before lunch-day support
        // automatically default to Monday-Friday.
        lunchDays = try container.decodeIfPresent(
            Set<SchoolLunchDay>.self,
            forKey: .lunchDays
        ) ?? Set(SchoolLunchDay.allCases)

        // Existing classes saved before custom ordering
        // automatically start at zero.
        sortOrder = try container.decodeIfPresent(
            Int.self,
            forKey: .sortOrder
        ) ?? 0
    }
}


// MARK: - School Lunch Day

enum SchoolLunchDay: Int, Codable, CaseIterable, Hashable, Sendable {

    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5

    var shortTitle: String {

        switch self {

        case .monday:
            return "Mon"

        case .tuesday:
            return "Tue"

        case .wednesday:
            return "Wed"

        case .thursday:
            return "Thu"

        case .friday:
            return "Fri"
        }
    }

    var title: String {

        switch self {

        case .monday:
            return "Monday"

        case .tuesday:
            return "Tuesday"

        case .wednesday:
            return "Wednesday"

        case .thursday:
            return "Thursday"

        case .friday:
            return "Friday"
        }
    }
}
