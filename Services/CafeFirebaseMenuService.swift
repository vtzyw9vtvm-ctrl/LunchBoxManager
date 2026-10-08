import Foundation
import FirebaseCore
import FirebaseFirestore

@MainActor
final class CafeFirebaseMenuService {

    private let db: Firestore

    init() {

        let cafeApp: FirebaseApp

        if let existingApp =
            FirebaseApp.app(
                name: "EspressoCafe"
            )
        {

            cafeApp = existingApp

        } else {

            guard
                let plistPath =
                    Bundle.main.path(
                        forResource:
                            "GoogleService-Info-Espresso",
                        ofType: "plist"
                    ),
                let options =
                    FirebaseOptions(
                        contentsOfFile:
                            plistPath
                    )
            else {
                fatalError(
                    "Could not load the Espresso Cafe Firebase configuration."
                )
            }

            FirebaseApp.configure(
                name: "EspressoCafe",
                options: options
            )

            guard let configuredApp =
                FirebaseApp.app(
                    name: "EspressoCafe"
                )
            else {
                fatalError(
                    "Could not configure the Espresso Cafe Firebase app."
                )
            }

            cafeApp = configuredApp
        }

        db = Firestore.firestore(
            app: cafeApp
        )
    }

    // MARK: - Upload Complete Cafe Menu

    func uploadMenu(
        categories: [LunchCategory],
        modifierGroups: [ModifierGroup]
    ) async throws {

        let menuDocument = db
            .collection("cafe_menu")
            .document("current")

        var categoryData: [[String: Any]] = []

        for category in categories {

            var itemData: [[String: Any]] = []

            for item in category.items {

                let linkedGroups =
                    modifierGroups.filter {
                        item.modifierGroups.contains(
                            $0.id
                        )
                    }

                let groupsData:
                    [[String: Any]] =
                    linkedGroups.map { group in

                        let modifiersData:
                            [[String: Any]] =
                            group.modifiers.map {
                                modifier in

                                [
                                    "id":
                                        modifier.id
                                            .uuidString,
                                    "name":
                                        modifier.name,
                                    "price":
                                        modifier.price,
                                    "isDefault":
                                        modifier.isDefault,
                                    "isAvailable":
                                        modifier.isAvailable
                                ]
                            }

                        return [
                            "id":
                                group.id.uuidString,
                            "name":
                                group.name,
                            "customerName":
                                group.customerName,
                            "minimumSelections":
                                group.minimumSelections,
                            "maximumSelections":
                                group.maximumSelections,
                            "useRadioButtons":
                                group.useRadioButtons,
                            "allowQuantities":
                                group.allowQuantities,
                            "modifiers":
                                modifiersData
                        ]
                    }

                itemData.append(
                    [
                        "id":
                            item.id.uuidString,
                        "sortOrder":
                            item.sortOrder,
                        "name":
                            item.name,
                        "description":
                            item.description,
                        "category":
                            item.category,
                        "price":
                            item.price,
                        "costPrice":
                            item.costPrice,
                        "gstIncluded":
                            item.gstIncluded,
                        "isActive":
                            item.isActive,
                        "isSoldOut":
                            item.isSoldOut,
                        "isFeatured":
                            item.isFeatured,
                        "allowNotes":
                            item.allowNotes,
                        "imageName":
                            item.imageName,
                        "imageURL":
                            item.imageURL,
                        "isHot":
                            item.isHot,
                        "isCold":
                            item.isCold,
                        "isGlutenFree":
                            item.isGlutenFree,
                        "isVegan":
                            item.isVegan,
                        "isVegetarian":
                            item.isVegetarian,
                        "isHalal":
                            item.isHalal,
                        "multiBuyEnabled": item.multiBuyEnabled,
                        "multiBuyQuantity": item.multiBuyQuantity,
                        "multiBuyPrice": item.multiBuyPrice,
                        "modifierGroups":
                            groupsData
                    ]
                )
            }

            categoryData.append(
                [
                    "id":
                        category.id.uuidString,
                    "sortOrder":
                        category.sortOrder,
                    "name":
                        category.name,
                    "icon":
                        category.icon,
                    "items":
                        itemData
                ]
            )
        }

        let masterModifierGroupsData: [[String: Any]] =
            modifierGroups.enumerated().map { index, group in

                let modifiersData: [[String: Any]] =
                    group.modifiers.enumerated().map { modifierIndex, modifier in

                        [
                            "id": modifier.id.uuidString,
                            "sortOrder": modifierIndex,
                            "name": modifier.name,
                            "price": modifier.price,
                            "isDefault": modifier.isDefault,
                            "isAvailable": modifier.isAvailable
                        ]
                    }

                return [
                    "id": group.id.uuidString,
                    "sortOrder": index,
                    "name": group.name,
                    "customerName": group.customerName,
                    "minimumSelections": group.minimumSelections,
                    "maximumSelections": group.maximumSelections,
                    "useRadioButtons": group.useRadioButtons,
                    "allowQuantities": group.allowQuantities,
                    "modifiers": modifiersData
                ]
            }

        let data: [String: Any] = [
            "categories": categoryData,
            "modifierGroups": masterModifierGroupsData,
            "updatedAt": FieldValue.serverTimestamp(),
            "version": 2
        ]

        try await menuDocument.setData(
            data
        )

        print(
            "☕️ CAFE MENU PUBLISHED TO ESPRESSO FIREBASE"
        )
    }

    // MARK: - Load Cafe Menu

    func loadMenu()
        async throws -> [LunchCategory]
    {

        let document =
            try await db
                .collection("cafe_menu")
                .document("current")
                .getDocument()

        guard
            let data = document.data(),
            let firebaseCategories =
                data["categories"]
                    as? [[String: Any]]
        else {
            return []
        }

        var categories:
            [LunchCategory] = []

        for categoryData
            in firebaseCategories
        {

            let categoryID =
                UUID(
                    uuidString:
                        categoryData["id"]
                            as? String
                        ?? ""
                )
                ?? UUID()

            let categoryName =
                categoryData["name"]
                    as? String
                ?? ""

            let categoryIcon =
                categoryData["icon"]
                    as? String
                ?? "🍽️"

            let categorySortOrder =
                categoryData["sortOrder"]
                    as? Int
                ?? 0

            let firebaseItems =
                categoryData["items"]
                    as? [[String: Any]]
                ?? []

            var items:
                [LunchMenuItem] = []

            for itemData
                in firebaseItems
            {

                let itemID =
                    UUID(
                        uuidString:
                            itemData["id"]
                                as? String
                            ?? ""
                    )
                    ?? UUID()

                let firebaseGroups =
                    itemData[
                        "modifierGroups"
                    ]
                    as? [[String: Any]]
                    ?? []

                let modifierGroupIDs:
                    [UUID] =
                    firebaseGroups
                        .compactMap {
                            group in

                            guard
                                let id =
                                    group["id"]
                                        as? String
                            else {
                                return nil
                            }

                            return UUID(
                                uuidString: id
                            )
                        }

                let item =
                    LunchMenuItem(
                        id: itemID,

                        sortOrder:
                            itemData[
                                "sortOrder"
                            ] as? Int
                            ?? 0,

                        name:
                            itemData["name"]
                                as? String
                            ?? "",

                        description:
                            itemData[
                                "description"
                            ] as? String
                            ?? "",

                        category:
                            itemData[
                                "category"
                            ] as? String
                            ?? categoryName,

                        price:
                            (
                                itemData["price"]
                                    as? NSNumber
                            )?.doubleValue
                            ?? 0,

                        costPrice:
                            (
                                itemData[
                                    "costPrice"
                                ] as? NSNumber
                            )?.doubleValue
                            ?? 0,

                        gstIncluded:
                            itemData[
                                "gstIncluded"
                            ] as? Bool
                            ?? true,

                        isActive:
                            itemData[
                                "isActive"
                            ] as? Bool
                            ?? true,

                        isSoldOut:
                            itemData[
                                "isSoldOut"
                            ] as? Bool
                            ?? false,

                        isFeatured:
                            itemData[
                                "isFeatured"
                            ] as? Bool
                            ?? false,

                        allowNotes:
                            itemData[
                                "allowNotes"
                            ] as? Bool
                            ?? true,

                        imageName:
                            itemData[
                                "imageName"
                            ] as? String
                            ?? "",

                        imageURL:
                            itemData[
                                "imageURL"
                            ] as? String
                            ?? "",

                        modifierGroups:
                            modifierGroupIDs,

                        isHot:
                            itemData["isHot"]
                                as? Bool
                            ?? true,

                        isCold:
                            itemData["isCold"]
                                as? Bool
                            ?? false,

                        isGlutenFree:
                            itemData[
                                "isGlutenFree"
                            ] as? Bool
                            ?? false,

                        isVegan:
                            itemData[
                                "isVegan"
                            ] as? Bool
                            ?? false,

                        isVegetarian:
                            itemData[
                                "isVegetarian"
                            ] as? Bool
                            ?? false,

                        isHalal:
                            itemData["isHalal"]
                                as? Bool
                            ?? false,

                        multiBuyEnabled:
                            itemData["multiBuyEnabled"]
                                as? Bool
                            ?? false,

                        multiBuyQuantity:
                            itemData["multiBuyQuantity"]
                                as? Int
                            ?? 2,

                        multiBuyPrice:
                            itemData["multiBuyPrice"]
                                as? Double
                            ?? 0
                        )

                items.append(item)
            }

            var category =
                LunchCategory(
                    id: categoryID,
                    name: categoryName,
                    icon: categoryIcon,
                    items: items
                )

            category.sortOrder =
                categorySortOrder

            categories.append(category)
        }

        return categories.sorted {
            $0.sortOrder < $1.sortOrder
        }
    }

    // MARK: - Load Cafe Modifier Groups

    func loadModifierGroups()
        async throws -> [ModifierGroup]
    {
        
        func decodeModifierGroup(
            _ groupData: [String: Any]
        ) -> (group: ModifierGroup, sortOrder: Int)? {

            guard
                let idString = groupData["id"] as? String,
                let groupID = UUID(uuidString: idString)
            else {
                return nil
            }

            let firebaseModifiers =
                groupData["modifiers"] as? [[String: Any]]
                ?? []

            let modifiers: [(modifier: Modifier, sortOrder: Int)] =
                firebaseModifiers.compactMap { modifierData in

                    guard
                        let idString =
                            modifierData["id"] as? String,
                        let modifierID =
                            UUID(uuidString: idString)
                    else {
                        return nil
                    }

                    let modifier = Modifier(
                        id: modifierID,
                        name:
                            modifierData["name"] as? String
                            ?? "",
                        price:
                            (
                                modifierData["price"]
                                    as? NSNumber
                            )?.doubleValue
                            ?? 0,
                        isDefault:
                            modifierData["isDefault"] as? Bool
                            ?? false,
                        isAvailable:
                            modifierData["isAvailable"] as? Bool
                            ?? true
                    )

                    return (
                        modifier,
                        modifierData["sortOrder"] as? Int
                            ?? 0
                    )
                }

            let sortedModifiers =
                modifiers
                    .sorted {
                        $0.sortOrder < $1.sortOrder
                    }
                    .map {
                        $0.modifier
                    }

            let group = ModifierGroup(
                id: groupID,
                name:
                    groupData["name"] as? String
                    ?? "Modifier Group",
                customerName:
                    groupData["customerName"] as? String
                    ?? groupData["name"] as? String
                    ?? "Modifier Group",
                minimumSelections:
                    (
                        groupData["minimumSelections"]
                            as? NSNumber
                    )?.intValue
                    ?? 0,
                maximumSelections:
                    (
                        groupData["maximumSelections"]
                            as? NSNumber
                    )?.intValue
                    ?? 99,
                useRadioButtons:
                    groupData["useRadioButtons"] as? Bool
                    ?? false,
                allowQuantities:
                    groupData["allowQuantities"] as? Bool
                    ?? false,
                modifiers: sortedModifiers
            )

            return (
                group,
                groupData["sortOrder"] as? Int ?? 0
            )
        }

        let document =
            try await db
                .collection("cafe_menu")
                .document("current")
                .getDocument()

        guard let data = document.data() else {
            return []
        }

        // Prefer the new master modifier-group list.
        // Older Firebase data will fall back to the
        // modifier groups embedded inside menu items.
        if let masterGroups =
            data["modifierGroups"] as? [[String: Any]],
           !masterGroups.isEmpty {

            let decodedGroups =
                masterGroups
                    .compactMap {
                        decodeModifierGroup($0)
                    }
                    .sorted {
                        $0.sortOrder < $1.sortOrder
                    }
                    .map {
                        $0.group
                    }

            if !decodedGroups.isEmpty {
                return decodedGroups
            }
        }

        guard
            let firebaseCategories =
                data["categories"] as? [[String: Any]]
        else {
            return []
        }

        var groupsByID:
            [UUID: ModifierGroup] = [:]

        for categoryData
            in firebaseCategories
        {

            let firebaseItems =
                categoryData["items"]
                    as? [[String: Any]]
                ?? []

            for itemData
                in firebaseItems
            {

                let firebaseGroups =
                    itemData[
                        "modifierGroups"
                    ]
                    as? [[String: Any]]
                    ?? []

                for groupData
                    in firebaseGroups
                {

                    guard
                        let idString =
                            groupData["id"]
                                as? String,
                        let groupID =
                            UUID(
                                uuidString:
                                    idString
                            )
                    else {
                        continue
                    }

                    if groupsByID[
                        groupID
                    ] != nil {
                        continue
                    }

                    let firebaseModifiers =
                        groupData[
                            "modifiers"
                        ]
                        as? [[String: Any]]
                        ?? []

                    let modifiers:
                        [Modifier] =
                        firebaseModifiers.map {
                            modifierData in

                            let modifierID =
                                UUID(
                                    uuidString:
                                        modifierData[
                                            "id"
                                        ]
                                        as? String
                                        ?? ""
                                )
                                ?? UUID()

                            return Modifier(
                                id:
                                    modifierID,

                                name:
                                    modifierData[
                                        "name"
                                    ] as? String
                                    ?? "",

                                price:
                                    (
                                        modifierData[
                                            "price"
                                        ] as? NSNumber
                                    )?.doubleValue
                                    ?? 0,

                                isDefault:
                                    modifierData[
                                        "isDefault"
                                    ] as? Bool
                                    ?? false,

                                isAvailable:
                                    modifierData[
                                        "isAvailable"
                                    ] as? Bool
                                    ?? true
                            )
                        }

                    let group =
                        ModifierGroup(
                            id:
                                groupID,

                            name:
                                groupData[
                                    "name"
                                ] as? String
                                ?? "Modifier Group",

                            customerName:
                                groupData[
                                    "customerName"
                                ] as? String
                                ?? groupData[
                                    "name"
                                ] as? String
                                ?? "Modifier Group",

                            minimumSelections:
                                (
                                    groupData[
                                        "minimumSelections"
                                    ] as? NSNumber
                                )?.intValue
                                ?? 0,

                            maximumSelections:
                                (
                                    groupData[
                                        "maximumSelections"
                                    ] as? NSNumber
                                )?.intValue
                                ?? 99,

                            useRadioButtons:
                                groupData[
                                    "useRadioButtons"
                                ] as? Bool
                                ?? false,

                            allowQuantities:
                                groupData[
                                    "allowQuantities"
                                ] as? Bool
                                ?? false,

                            modifiers:
                                modifiers
                        )

                    groupsByID[
                        groupID
                    ] = group
                }
            }
        }

        return Array(
            groupsByID.values
        )
        .sorted {
            $0.name
                .localizedCaseInsensitiveCompare(
                    $1.name
                )
                == .orderedAscending
        }
    }
    // MARK: - Save Cafe Modifier Groups

    func saveModifierGroups(
        _ modifierGroups: [ModifierGroup]
    ) async throws {

        let modifierGroupsData: [[String: Any]] =
            modifierGroups.enumerated().map { index, group in

                let modifiersData: [[String: Any]] =
                    group.modifiers.enumerated().map {
                        modifierIndex,
                        modifier in

                        [
                            "id": modifier.id.uuidString,
                            "sortOrder": modifierIndex,
                            "name": modifier.name,
                            "price": modifier.price,
                            "isDefault": modifier.isDefault,
                            "isAvailable": modifier.isAvailable
                        ]
                    }

                return [
                    "id": group.id.uuidString,
                    "sortOrder": index,
                    "name": group.name,
                    "customerName": group.customerName,
                    "minimumSelections": group.minimumSelections,
                    "maximumSelections": group.maximumSelections,
                    "useRadioButtons": group.useRadioButtons,
                    "allowQuantities": group.allowQuantities,
                    "modifiers": modifiersData
                ]
            }

        try await db
            .collection("cafe_menu")
            .document("current")
            .setData(
                [
                    "modifierGroups": modifierGroupsData,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )

        print(
            "☕️ CAFE MODIFIER GROUPS SAVED TO ESPRESSO FIREBASE"
        )
    }
}
