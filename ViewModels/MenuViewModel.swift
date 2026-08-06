import Foundation
import SwiftUI

@Observable
final class MenuViewModel {

    private let saveKey = "LunchMenu"

    var categories: [LunchCategory] = [] {
        didSet {
            save()
        }
    }

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

    func items(for category: LunchCategory) -> [LunchMenuItem] {

        categories.first(where: { $0.id == category.id })?.items ?? []

    }

    func setItems(_ items: [LunchMenuItem], for category: LunchCategory) {

        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            return
        }

        categories[index].items = items

        save()

    }

    // MARK: - Save

    func save() {

        do {

            let data = try JSONEncoder().encode(categories)

            UserDefaults.standard.set(data, forKey: saveKey)

        } catch {

            print("Save failed:", error)

        }

    }

    // MARK: - Load

    private func load() {

        guard
            let data = UserDefaults.standard.data(forKey: saveKey)
        else {
            return
        }

        do {

            categories = try JSONDecoder().decode([LunchCategory].self, from: data)

        } catch {

            print("Load failed:", error)

        }

    }

}
