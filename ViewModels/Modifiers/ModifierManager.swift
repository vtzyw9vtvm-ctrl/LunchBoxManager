import Foundation

@Observable
final class ModifierManager {

    private let saveKey = "ModifierGroups"

    var groups: [ModifierGroup] = [] {
        didSet {
            save()
        }
    }

    init() {

        load()

        if groups.isEmpty {

            groups = [

                ModifierGroup(
                    name: "Extras",
                    modifiers: [

                        Modifier(name: "Cheese", price: 1.00),
                        Modifier(name: "Bacon", price: 3.00),
                        Modifier(name: "Egg", price: 2.00),
                        Modifier(name: "Hash Brown", price: 2.50)

                    ]
                ),

                ModifierGroup(
                    name: "Sauces",
                    modifiers: [

                        Modifier(name: "Tomato Sauce"),
                        Modifier(name: "BBQ Sauce"),
                        Modifier(name: "Aioli"),
                        Modifier(name: "Sweet Chilli")

                    ]
                ),

                ModifierGroup(
                    name: "Remove Ingredients",
                    modifiers: [

                        Modifier(name: "No Lettuce"),
                        Modifier(name: "No Tomato"),
                        Modifier(name: "No Mayo"),
                        Modifier(name: "No Onion")

                    ]
                )

            ]

            save()

        }

    }

    // MARK: - Groups

    @discardableResult
    func addGroup() -> ModifierGroup {

        let group = ModifierGroup(
            name: "New Group",
            modifiers: [
                Modifier(
                    name: "New Modifier",
                    price: 0
                )
            ]
        )

        groups.append(group)

        return group

    }

    func deleteGroup(_ group: ModifierGroup) {

        groups.removeAll {
            $0.id == group.id
        }

    }

    // MARK: - Modifiers

    @discardableResult
    func addModifier(to group: ModifierGroup) -> Modifier {

        let modifier = Modifier(
            name: "New Modifier",
            price: 0
        )

        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {

            return modifier

        }

        groups[index].modifiers.append(modifier)

        return modifier

    }

    func deleteModifier(
        _ modifier: Modifier,
        from group: ModifierGroup
    ) {

        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            return
        }

        groups[index].modifiers.removeAll {
            $0.id == modifier.id
        }

    }

    @discardableResult
    func duplicateModifier(
        _ modifier: Modifier,
        in group: ModifierGroup
    ) -> Modifier {

        var copy = modifier
        copy.id = UUID()
        copy.name += " Copy"

        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {

            return copy

        }

        groups[index].modifiers.append(copy)

        return copy

    }

    // MARK: - Save

    func save() {

        do {

            let data = try JSONEncoder().encode(groups)

            UserDefaults.standard.set(
                data,
                forKey: saveKey
            )

        }

        catch {

            print(error)

        }

    }

    // MARK: - Load

    private func load() {

        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return
        }

        do {

            groups = try JSONDecoder().decode(
                [ModifierGroup].self,
                from: data
            )

        }

        catch {

            print(error)

        }

    }

}
