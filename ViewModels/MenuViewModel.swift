import Foundation
import SwiftUI

@Observable
final class MenuViewModel {

    private let saveKey = "LunchMenu"

    var categories: [LunchCategory] = []

    init() {

        load()

        if categories.isEmpty {

            categories = [

                LunchCategory(
                    name: "Hot Food",
                    icon: "🍔",
                    items: [

                        LunchMenuItem(
                            name: "Bacon & Egg Roll",
                            description: "Seeded brioche bun with bacon and egg",
                            price: 8.50,
                            imageName: "bacon_egg_roll"
                        ),

                        LunchMenuItem(
                            name: "Chicken Burger",
                            description: "Crumbed chicken, lettuce and mayo",
                            price: 10.50,
                            imageName: "chicken_burger"
                        ),

                        LunchMenuItem(
                            name: "Fish & Chips",
                            description: "Battered fish with chips",
                            price: 11.00,
                            imageName: "fish_chips"
                        ),

                        LunchMenuItem(
                            name: "Nuggets & Chips",
                            description: "Six nuggets with chips",
                            price: 8.00,
                            imageName: "nuggets"
                        )

                    ]
                ),

                LunchCategory(
                    name: "Sandwiches",
                    icon: "🥪"
                ),

                LunchCategory(
                    name: "Snacks",
                    icon: "🍪"
                ),

                LunchCategory(
                    name: "Drinks",
                    icon: "🥤"
                )

            ]

            save()

        }

    }

    // MARK: - Categories

    @discardableResult
    func addCategory() -> LunchCategory {

        let category = LunchCategory(
            name: "New Category",
            icon: "🍽️",
            items: [
                LunchMenuItem(
                    name: "New Item",
                    description: "",
                    category: "New Category",
                    price: 0
                )
            ]
        )

        categories.append(category)

        save()

        return category

    }

    func updateCategory(_ category: LunchCategory) {

        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            return
        }

        categories[index] = category

        save()

    }

    func deleteCategory(_ category: LunchCategory) {

        categories.removeAll {
            $0.id == category.id
        }

        save()

    }

    // MARK: - Items

    func items(for category: LunchCategory) -> [LunchMenuItem] {

        categories.first(where: { $0.id == category.id })?.items ?? []

    }

    func setItems(_ items: [LunchMenuItem], for category: LunchCategory) {

        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            return
        }

        var updatedCategory = categories[index]
        updatedCategory.items = items

        categories[index] = updatedCategory

        save()

    }

    @discardableResult
    func addItem(to category: LunchCategory) -> LunchMenuItem {

        let item = LunchMenuItem(
            name: "New Item",
            description: "",
            category: category.name,
            price: 0
        )

        var items = items(for: category)
        items.append(item)

        setItems(items, for: category)

        return item

    }

    func updateItem(
        _ item: LunchMenuItem,
        in category: LunchCategory
    ) {

        var items = items(for: category)

        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        items[index] = item

        setItems(items, for: category)

    }

    func deleteItem(
        _ item: LunchMenuItem,
        from category: LunchCategory
    ) {

        var items = items(for: category)

        items.removeAll {
            $0.id == item.id
        }

        setItems(items, for: category)

    }

    @discardableResult
    func duplicateItem(
        _ item: LunchMenuItem,
        in category: LunchCategory
    ) -> LunchMenuItem {

        var copy = item

        copy.id = UUID()
        copy.name += " Copy"

        var items = items(for: category)
        items.append(copy)

        setItems(items, for: category)

        return copy

    }

    // MARK: - Persistence

    func save() {

        do {

            let data = try JSONEncoder().encode(categories)

            UserDefaults.standard.set(
                data,
                forKey: saveKey
            )

        }

        catch {

            print("Menu save failed:", error)

        }

    }

    private func load() {

        guard
            let data = UserDefaults.standard.data(forKey: saveKey)
        else {
            return
        }

        do {

            categories = try JSONDecoder().decode(
                [LunchCategory].self,
                from: data
            )

        }

        catch {

            print("Menu load failed:", error)

        }

    }

}
