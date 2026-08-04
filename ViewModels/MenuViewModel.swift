import Foundation
import SwiftUI

@Observable
final class MenuViewModel {

    var categories: [LunchCategory]

    init() {

        categories = [

            LunchCategory(
                name: "Hot Food",
                icon: "🍔",
                items: [

                    LunchMenuItem(
                        name: "Bacon & Egg Roll",
                        description: "Seeded brioche bun with bacon and egg",
                        price: 8.50,
                        imageName: "bacon_egg"
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
    }

    func items(for category: LunchCategory) -> [LunchMenuItem] {

        categories.first(where: { $0.id == category.id })?.items ?? []

    }

    func setItems(_ items: [LunchMenuItem], for category: LunchCategory) {

        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            return
        }

        categories[index].items = items

    }

}
