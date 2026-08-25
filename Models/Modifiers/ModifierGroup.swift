import Foundation

struct ModifierGroup: Identifiable, Codable, Hashable {

    var id = UUID()
    var name: String
    var minimumSelections: Int = 0
    var maximumSelections: Int = 99
    var useRadioButtons: Bool = false

    /// Allows the customer to choose a separate quantity
    /// for modifiers in this group.
    var allowQuantities: Bool = false

    var modifiers: [Modifier] = []

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case minimumSelections
        case maximumSelections
        case useRadioButtons
        case allowQuantities
        case modifiers
    }

    // MARK: - Initialiser

    init(
        id: UUID = UUID(),
        name: String,
        minimumSelections: Int = 0,
        maximumSelections: Int = 99,
        useRadioButtons: Bool = false,
        allowQuantities: Bool = false,
        modifiers: [Modifier] = []
    ) {
        self.id = id
        self.name = name
        self.minimumSelections = minimumSelections
        self.maximumSelections = maximumSelections
        self.useRadioButtons = useRadioButtons
        self.allowQuantities = allowQuantities
        self.modifiers = modifiers
    }

    // MARK: - Backwards-Compatible Decoder

    init(from decoder: Decoder) throws {

        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decodeIfPresent(
            UUID.self,
            forKey: .id
        ) ?? UUID()

        name = try container.decodeIfPresent(
            String.self,
            forKey: .name
        ) ?? "Modifier Group"

        minimumSelections = try container.decodeIfPresent(
            Int.self,
            forKey: .minimumSelections
        ) ?? 0

        maximumSelections = try container.decodeIfPresent(
            Int.self,
            forKey: .maximumSelections
        ) ?? 99

        useRadioButtons = try container.decodeIfPresent(
            Bool.self,
            forKey: .useRadioButtons
        ) ?? false

        // Older saved modifier groups don't contain this.
        allowQuantities = try container.decodeIfPresent(
            Bool.self,
            forKey: .allowQuantities
        ) ?? false

        modifiers = try container.decodeIfPresent(
            [Modifier].self,
            forKey: .modifiers
        ) ?? []
    }
}
