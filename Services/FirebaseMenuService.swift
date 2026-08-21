import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseMenuService {

    private let db = Firestore.firestore()

    // MARK: - Upload Complete Menu

    func uploadMenu(
        categories: [LunchCategory],
        modifierGroups: [ModifierGroup]
    ) async throws {

        let menuDocument = db
            .collection("school_menu")
            .document("current")

        var categoryData: [[String: Any]] = []

        for category in categories {

            var itemData: [[String: Any]] = []

            for item in category.items {

                let linkedGroups = modifierGroups.filter {
                    item.modifierGroups.contains($0.id)
                }

                let groupsData: [[String: Any]] = linkedGroups.map { group in

                    let modifiersData: [[String: Any]] = group.modifiers.map { modifier in
                        [
                            "id": modifier.id.uuidString,
                            "name": modifier.name,
                            "price": modifier.price,
                            "isDefault": modifier.isDefault,
                            "isAvailable": modifier.isAvailable
                        ]
                    }

                    return [
                        "id": group.id.uuidString,
                        "name": group.name,
                        "minimumSelections": group.minimumSelections,
                        "maximumSelections": group.maximumSelections,
                        "useRadioButtons": group.useRadioButtons,
                        "modifiers": modifiersData
                    ]
                }

                itemData.append([
                    "id": item.id.uuidString,
                    "sortOrder": item.sortOrder,
                    "name": item.name,
                    "description": item.description,
                    "category": item.category,
                    "price": item.price,
                    "costPrice": item.costPrice,
                    "gstIncluded": item.gstIncluded,
                    "isActive": item.isActive,
                    "isSoldOut": item.isSoldOut,
                    "isFeatured": item.isFeatured,
                    "imageName": item.imageName,
                    "isHot": item.isHot,
                    "isCold": item.isCold,
                    "modifierGroups": groupsData
                ])
            }

            categoryData.append([
                "id": category.id.uuidString,
                "sortOrder": category.sortOrder,
                "name": category.name,
                "icon": category.icon,
                "items": itemData
            ])
        }

        let data: [String: Any] = [
            "categories": categoryData,
            "updatedAt": FieldValue.serverTimestamp(),
            "version": 1
        ]

        try await menuDocument.setData(data)
    }
}
