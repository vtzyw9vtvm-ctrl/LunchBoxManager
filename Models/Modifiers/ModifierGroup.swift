import Foundation

struct ModifierGroup: Identifiable, Codable, Hashable {

    var id = UUID()

    var name: String

    var minimumSelections: Int = 0

    var maximumSelections: Int = 99

    var useRadioButtons: Bool = false

    var modifiers: [Modifier] = []

}
