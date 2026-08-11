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

        let items = categories.first(where: { $0.id == category.id })?.items ?? []

        return items.sorted {

            if $0.isFeatured != $1.isFeatured {
                return $0.isFeatured && !$1.isFeatured
            }

            return $0.sortOrder < $1.sortOrder

        }

    }

    func setItems(_ items: [LunchMenuItem], for category: LunchCategory) {

        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            return
        }

        var reorderedItems = items

        for i in reorderedItems.indices {
            reorderedItems[i].sortOrder = i
        }

        var updatedCategory = categories[index]
        updatedCategory.items = reorderedItems

        categories[index] = updatedCategory

        save()

    }
    
    func moveItems(
        from source: IndexSet,
        to destination: Int,
        in category: LunchCategory
    ) {

        var items = items(for: category)

        items.move(
            fromOffsets: source,
            toOffset: destination
        )

        setItems(
            items,
            for: category
        )

    }
    func moveItem(
        withId itemID: UUID,
        to newIndex: Int,
        in category: LunchCategory
    ) {

        var items = items(for: category)

        guard let oldIndex = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        let item = items.remove(at: oldIndex)

        items.insert(item, at: newIndex)

        setItems(items, for: category)

    }
    
    func moveItemUp(
        _ item: LunchMenuItem,
        in category: LunchCategory
    ) {

        var items = items(for: category)

        guard
            let index = items.firstIndex(where: { $0.id == item.id }),
            index > 0
        else { return }

        items.swapAt(index, index - 1)

        setItems(items, for: category)

    }

    func moveItemDown(
        _ item: LunchMenuItem,
        in category: LunchCategory
    ) {

        var items = items(for: category)

        guard
            let index = items.firstIndex(where: { $0.id == item.id }),
            index < items.count - 1
        else { return }

        items.swapAt(index, index + 1)

        setItems(items, for: category)

    }

    @discardableResult
    func addItem(to category: LunchCategory) -> LunchMenuItem {

        let item = LunchMenuItem(
            sortOrder: items(for: category).count,
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

        var updatedItem = item
        updatedItem.lastEdited = Date()

        items[index] = updatedItem

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
        copy.sortOrder = items(for: category).count

        var items = items(for: category)
        items.append(copy)

        setItems(items, for: category)

        return copy

    }
    @discardableResult
    func duplicateCategory(
        _ category: LunchCategory
    ) -> LunchCategory {

        var copy = category

        copy.id = UUID()
        copy.name += " Copy"

        for index in copy.items.indices {
            copy.items[index].id = UUID()
            copy.items[index].sortOrder = index
        }

        categories.append(copy)

        save()

        return copy

    }
    
    var totalMenuItems: Int {

        categories.reduce(0) { total, category in
            total + category.items.count
        }

    }

    var activeMenuItems: Int {

        categories.reduce(0) { total, category in
            total + category.items.filter(\.isActive).count
        }

    }

    var featuredMenuItems: Int {

        categories.reduce(0) { total, category in
            total + category.items.filter(\.isFeatured).count
        }

    }

    var averageSellPrice: Double {

        let items = categories.flatMap(\.items)

        guard !items.isEmpty else { return 0 }

        return items.reduce(0) { $0 + $1.price } / Double(items.count)

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
