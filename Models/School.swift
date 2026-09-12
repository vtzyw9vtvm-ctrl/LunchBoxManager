import Foundation

/// Represents a school participating in the lunch ordering system.
struct School: Identifiable, Codable, Hashable, Sendable {

    let id: UUID

    var name: String
    var shortName: String

    var isActive = true
    var orderCutoffTime = "8:30 AM"
    var deliveryTime = "12:30 PM"

    var notes = ""

    /// Editable weekly lunch service rules.
    ///
    /// Each year level can have its own available weekdays.
    /// These are synced to Firebase so the parent app
    /// automatically follows the Manager settings.
    var orderingRules: [SchoolOrderingRule]

    /// Dates when this school is not accepting lunch orders.
    ///
    /// A closure can represent a single day or a date range,
    /// such as a curriculum day or school holidays.
    var closures: [SchoolClosure]

    init(
        id: UUID = UUID(),
        name: String,
        shortName: String,
        isActive: Bool = true,
        orderCutoffTime: String = "8:30 AM",
        deliveryTime: String = "12:30 PM",
        notes: String = "",
        orderingRules: [SchoolOrderingRule] = [],
        closures: [SchoolClosure] = []
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.isActive = isActive
        self.orderCutoffTime = orderCutoffTime
        self.deliveryTime = deliveryTime
        self.notes = notes
        self.orderingRules = orderingRules
        self.closures = closures
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName
        case isActive
        case orderCutoffTime
        case deliveryTime
        case notes
        case orderingRules
        case closures
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

        shortName = try container.decode(
            String.self,
            forKey: .shortName
        )

        isActive = try container.decodeIfPresent(
            Bool.self,
            forKey: .isActive
        ) ?? true

        orderCutoffTime = try container.decodeIfPresent(
            String.self,
            forKey: .orderCutoffTime
        ) ?? "8:30 AM"

        deliveryTime = try container.decodeIfPresent(
            String.self,
            forKey: .deliveryTime
        ) ?? "12:30 PM"

        notes = try container.decodeIfPresent(
            String.self,
            forKey: .notes
        ) ?? ""

        // Existing saved schools may not contain ordering rules.
        // They will simply start with no rules.
        orderingRules = try container.decodeIfPresent(
            [SchoolOrderingRule].self,
            forKey: .orderingRules
        ) ?? []

        // Existing saved schools will not yet contain closures.
        // They will simply start with no closures.
        closures = try container.decodeIfPresent(
            [SchoolClosure].self,
            forKey: .closures
        ) ?? []
    }
}


// MARK: - School Ordering Rule

struct SchoolOrderingRule:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: UUID

    /// Example:
    /// "Prep", "Grade 1", "Grade 2"
    var yearLevel: String

    /// Calendar weekday numbers:
    ///
    /// 2 = Monday
    /// 3 = Tuesday
    /// 4 = Wednesday
    /// 5 = Thursday
    /// 6 = Friday
    var weekdays: Set<Int>

    init(
        id: UUID = UUID(),
        yearLevel: String,
        weekdays: Set<Int> = []
    ) {
        self.id = id
        self.yearLevel = yearLevel
        self.weekdays = weekdays
    }
}


// MARK: - School Closure

struct SchoolClosure:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: UUID

    /// First closed school day.
    var startDate: Date

    /// Last closed school day.
    ///
    /// For a single-day closure this is the same
    /// date as startDate.
    var endDate: Date

    /// Optional explanation shown in Manager.
    ///
    /// Examples:
    /// "School Holidays"
    /// "Curriculum Day"
    /// "School Event"
    var reason: String

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        reason: String = ""
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.reason = reason
    }
}
