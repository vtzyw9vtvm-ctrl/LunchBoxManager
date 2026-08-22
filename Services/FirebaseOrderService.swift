import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseOrderService {

    private let db = Firestore.firestore()

    func loadOrders() async throws -> [LunchOrder] {

        let snapshot = try await db
            .collection("orders")
            .getDocuments()

        var lunchOrders: [LunchOrder] = []

        for document in snapshot.documents {

            let data = document.data()

            // MARK: - Basic order information

            let orderNumber = String(document.documentID.prefix(8)).uppercased()

            let schoolName = data["school"] as? String ?? ""
            let className = data["className"] as? String ?? ""

            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""

            let notes = data["notes"] as? String

            // MARK: - Dates

            let orderDate: Date

            if let timestamp = data["createdAt"] as? Timestamp {
                orderDate = timestamp.dateValue()
            } else {
                orderDate = Date()
            }

            let deliveryDate: Date

            if let timestamp = data["deliveryDate"] as? Timestamp {
                deliveryDate = timestamp.dateValue()
            } else {
                deliveryDate = orderDate
            }

            // MARK: - Stable IDs

            let schoolID = stableUUID(from: "school-\(schoolName)")
            let classID = stableUUID(from: "class-\(schoolName)-\(className)")

            let firebaseChildID = data["childId"] as? String ?? document.documentID
            let studentID = stableUUID(from: "student-\(firebaseChildID)")

            let orderID = stableUUID(from: "order-\(document.documentID)")
            let studentOrderID = stableUUID(
                from: "student-order-\(document.documentID)-\(firebaseChildID)"
            )

            // MARK: - School

            let schoolShortName: String

            switch schoolName {
            case "Christ the Priest Primary School":
                schoolShortName = "CTP"

            case "Burnside Primary School":
                schoolShortName = "BPS"

            default:
                schoolShortName = schoolName
            }

            let school = School(
                id: schoolID,
                name: schoolName,
                shortName: schoolShortName
            )
            // MARK: - Class

            let schoolClass = SchoolClass(
                id: classID,
                name: className,
                schoolID: schoolID
            )

            // MARK: - Student

            let student = Student(
                id: studentID,
                firstName: firstName,
                lastName: lastName,
                classID: classID
            )

            // MARK: - Items

            let firebaseItems = data["items"] as? [[String: Any]] ?? []

            let menuItems: [MenuItem] = firebaseItems.map { itemData in

                let itemName = itemData["name"] as? String ?? ""
                let quantity = itemData["quantity"] as? Int ?? 1

                let isHot = itemData["isHot"] as? Bool ?? true
                let isCold = itemData["isCold"] as? Bool ?? false
                
                let rawItemNotes = itemData["notes"] as? String ?? ""
                let itemNotes = rawItemNotes
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let finalItemNotes: String? =
                    itemNotes.isEmpty ? nil : itemNotes

                let firebaseMenuItemID =
                    itemData["menuItemId"] as? String ??
                    itemData["id"] as? String ??
                    UUID().uuidString

                let selectedOptions =
                    itemData["selectedOptions"] as? [[String: Any]] ?? []

                let variants: [String] = selectedOptions.compactMap {
                    optionData in

                    guard let name = optionData["name"] as? String else {
                        return nil
                    }

                    return name
                }

                return MenuItem(
                    id: stableUUID(
                        from: "menu-item-\(firebaseMenuItemID)"
                    ),
                    name: itemName,
                    category: "",
                    variants: variants,
                    quantity: quantity,
                    notes: finalItemNotes,
                    isHot: isHot,
                    isCold: isCold
                )
            }
            
            let hotLabelPrinted = data["hotLabelPrinted"] as? Bool ?? false
            let coldLabelPrinted = data["coldLabelPrinted"] as? Bool ?? false

            // MARK: - Student Order

            let studentOrder = StudentOrder(
                id: studentOrderID,
                student: student,
                schoolClass: schoolClass,
                items: menuItems,
                hotLabelPrinted: hotLabelPrinted,
                coldLabelPrinted: coldLabelPrinted
            )

            // MARK: - Lunch Order

            let lunchOrder = LunchOrder(
                id: orderID,
                firebaseDocumentID: document.documentID,
                orderNumber: orderNumber,
                school: school,
                studentOrders: [studentOrder],
                orderDate: orderDate,
                deliveryDate: deliveryDate,
                status: .new,
                notes: notes
            )

            lunchOrders.append(lunchOrder)
        }

        return lunchOrders.sorted {
            $0.orderDate > $1.orderDate
        }
    }

    // MARK: - Printed Status

    func markHotLabelPrinted(orderID: String) async throws {
        try await db
            .collection("orders")
            .document(orderID)
            .updateData([
                "hotLabelPrinted": true,
                "hotLabelPrintedAt": FieldValue.serverTimestamp()
            ])
    }

    func markColdLabelPrinted(orderID: String) async throws {
        try await db
            .collection("orders")
            .document(orderID)
            .updateData([
                "coldLabelPrinted": true,
                "coldLabelPrintedAt": FieldValue.serverTimestamp()
            ])
    }
    
    // MARK: - Stable UUID

    private func stableUUID(from string: String) -> UUID {

        var bytes = Array(string.utf8)

        var hash1: UInt64 = 14695981039346656037
        var hash2: UInt64 = 1099511628211

        for byte in bytes {
            hash1 ^= UInt64(byte)
            hash1 &*= 1099511628211

            hash2 ^= UInt64(byte)
            hash2 &*= 14695981039346656037
        }

        var uuidBytes = [UInt8](repeating: 0, count: 16)

        for index in 0..<8 {
            uuidBytes[index] =
                UInt8((hash1 >> UInt64(index * 8)) & 0xff)

            uuidBytes[index + 8] =
                UInt8((hash2 >> UInt64(index * 8)) & 0xff)
        }

        return UUID(
            uuid: (
                uuidBytes[0],
                uuidBytes[1],
                uuidBytes[2],
                uuidBytes[3],
                uuidBytes[4],
                uuidBytes[5],
                uuidBytes[6],
                uuidBytes[7],
                uuidBytes[8],
                uuidBytes[9],
                uuidBytes[10],
                uuidBytes[11],
                uuidBytes[12],
                uuidBytes[13],
                uuidBytes[14],
                uuidBytes[15]
            )
        )
    }
}
