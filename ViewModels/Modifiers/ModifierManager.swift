import Foundation

@Observable
final class ModifierManager {

    var groups: [ModifierGroup] = []

    init() {

        groups = [

            ModifierGroup(
                name: "Extras",
                modifiers: [

                    Modifier(
                        name: "Cheese",
                        price: 1.00
                    ),

                    Modifier(
                        name: "Bacon",
                        price: 3.00
                    ),

                    Modifier(
                        name: "Egg",
                        price: 2.00
                    ),

                    Modifier(
                        name: "Hash Brown",
                        price: 2.50
                    )

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

    }

}
