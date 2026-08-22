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

                print(
                    "🔥 PUBLISHING ITEM:",
                    item.name,
                    "IMAGE URL:",
                    item.imageURL
                )

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
                    "allowNotes": item.allowNotes,
                    "imageName": item.imageName,
                    "imageURL": item.imageURL,
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

    // MARK: - Download / Restore Menu

    func loadMenu() async throws -> [LunchCategory] {

        let document = try await db
            .collection("school_menu")
            .document("current")
            .getDocument()

        guard
            let data = document.data(),
            let firebaseCategories =
                data["categories"] as? [[String: Any]]
        else {
            return []
        }

        var categories: [LunchCategory] = []

        for categoryData in firebaseCategories {

            let categoryID =
                UUID(
                    uuidString:
                        categoryData["id"] as? String ?? ""
                ) ?? UUID()

            let categoryName =
                categoryData["name"] as? String ?? ""

            let categoryIcon =
                categoryData["icon"] as? String ?? "🍽️"

            let categorySortOrder =
                categoryData["sortOrder"] as? Int ?? 0

            let firebaseItems =
                categoryData["items"] as? [[String: Any]] ?? []

            var items: [LunchMenuItem] = []

            for itemData in firebaseItems {

                let itemID =
                    UUID(
                        uuidString:
                            itemData["id"] as? String ?? ""
                    ) ?? UUID()

                let firebaseGroups =
                    itemData["modifierGroups"]
                        as? [[String: Any]] ?? []

                let modifierGroupIDs: [UUID] =
                    firebaseGroups.compactMap { group in

                        guard
                            let id = group["id"] as? String
                        else {
                            return nil
                        }

                        return UUID(uuidString: id)
                    }

                let item = LunchMenuItem(
                    id: itemID,

                    sortOrder:
                        itemData["sortOrder"] as? Int ?? 0,

                    name:
                        itemData["name"] as? String ?? "",

                    description:
                        itemData["description"] as? String ?? "",

                    category:
                        itemData["category"] as? String
                        ?? categoryName,

                    price:
                        (itemData["price"] as? NSNumber)?
                            .doubleValue ?? 0,

                    costPrice:
                        (itemData["costPrice"] as? NSNumber)?
                            .doubleValue ?? 0,

                    gstIncluded:
                        itemData["gstIncluded"] as? Bool
                        ?? true,

                    isActive:
                        itemData["isActive"] as? Bool
                        ?? true,

                    isSoldOut:
                        itemData["isSoldOut"] as? Bool
                        ?? false,

                    isFeatured:
                        itemData["isFeatured"] as? Bool
                        ?? false,

                    // Existing Firebase items won't have
                    // this yet, so default to ON.
                    allowNotes:
                        itemData["allowNotes"] as? Bool
                        ?? true,

                    imageName:
                        itemData["imageName"] as? String
                        ?? "",

                    imageURL:
                        itemData["imageURL"] as? String
                        ?? "",

                    modifierGroups:
                        modifierGroupIDs,

                    isHot:
                        itemData["isHot"] as? Bool
                        ?? true,

                    isCold:
                        itemData["isCold"] as? Bool
                        ?? false
                )

                items.append(item)
            }

            var category = LunchCategory(
                id: categoryID,
                name: categoryName,
                icon: categoryIcon,
                items: items
            )

            category.sortOrder = categorySortOrder

            categories.append(category)
        }

        return categories.sorted {
            $0.sortOrder < $1.sortOrder
        }
    }
}
