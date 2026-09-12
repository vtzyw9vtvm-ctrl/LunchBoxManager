import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
final class FirebaseOrderService {
    
    private let db = Firestore.firestore()
    
    func loadOrders() async throws -> [LunchOrder] {
        
        let snapshot = try await db
            .collection("orders")
            .getDocuments()
        
        return try makeLunchOrders(from: snapshot.documents)
    }
    
    private func makeLunchOrders(
        from documents: [QueryDocumentSnapshot]
    ) throws -> [LunchOrder] {
        
        var lunchOrders: [LunchOrder] = []
        
        for document in documents {
            let data = document.data()
            
            // MARK: - Order Status

            let orderStatus =
                (data["status"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()

            let paymentStatus =
                (data["paymentStatus"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()

            // Cancelled/refunded orders are intentionally kept.
            // OrdersViewModel will place them in History so they remain
            // available as a permanent transaction record.

            let lunchOrderStatus: LunchOrderStatus

            if orderStatus == "cancelled" || paymentStatus == "refunded" {
                lunchOrderStatus = .cancelled
            } else {
                switch orderStatus {
                case "processing":
                    lunchOrderStatus = .processing

                case "completed":
                    lunchOrderStatus = .completed

                default:
                    lunchOrderStatus = .new
                }
            }
            
            // MARK: - Basic order information
            
            let orderNumber: String
            
            if let number = data["orderNumber"] as? NSNumber {
                orderNumber = String(number.intValue)
            } else {
                orderNumber = String(document.documentID.prefix(8)).uppercased()
            }
            
            let schoolName = data["school"] as? String ?? ""
            let className = data["className"] as? String ?? ""
            
            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""

            let parentId = data["parentId"] as? String
            let parentEmail = data["parentEmail"] as? String

            let foodAllergies = (
                data["foodAllergies"] as? String ?? ""
            )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
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
                classID: classID,
                allergies: foodAllergies
            )
            
            // MARK: - Items
            
            let firebaseItems = data["items"] as? [[String: Any]] ?? []
            
            let menuItems: [MenuItem] = firebaseItems.map { itemData in
                
                let itemName = itemData["name"] as? String ?? ""
                let quantity = itemData["quantity"] as? Int ?? 1
                let refundedQuantity =
                    (itemData["refundedQuantity"] as? NSNumber)?
                        .intValue ?? 0

                let refundedAmount =
                    (itemData["refundedAmount"] as? NSNumber)?
                        .doubleValue ?? 0
                let isHot = itemData["isHot"] as? Bool ?? true
                let isCold = itemData["isCold"] as? Bool ?? false
                
                let rawItemNotes = itemData["notes"] as? String ?? ""
                let itemNotes = rawItemNotes
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let finalItemNotes: String? =
                itemNotes.isEmpty ? nil : itemNotes
                
                // The order item's own Firebase ID is important.
                // Refunds use this ID to identify the exact item
                // purchased in this specific order.
                //
                // Older orders may not contain an item ID, so fall
                // back to the menu item ID if necessary.
                let firebaseOrderItemID =
                itemData["id"] as? String ??
                itemData["menuItemId"] as? String ??
                UUID().uuidString
                
                let selectedOptions =
                itemData["selectedOptions"] as? [[String: Any]] ?? []
                
                let variants: [String] = selectedOptions.compactMap {
                    optionData in
                    
                    guard let name = optionData["name"] as? String else {
                        return nil
                    }
                    
                    // Modifier quantity sent from the parent app.
                    // Older orders won't have this field, so default to 1.
                    let modifierQuantity =
                    (optionData["quantity"] as? NSNumber)?.intValue ?? 1
                    
                    // Only show the quantity when more than one
                    // modifier was ordered.
                    if modifierQuantity > 1 {
                        return "\(name) ×\(modifierQuantity)"
                    }
                    
                    return name
                }
                
                return MenuItem(
                    id: stableUUID(
                        from: "order-item-\(firebaseOrderItemID)"
                    ),
                    firebaseOrderItemID: firebaseOrderItemID,
                    name: itemName,
                    category: "",
                    variants: variants,
                    quantity: quantity,
                    refundedQuantity: refundedQuantity,
                    refundedAmount: refundedAmount,
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
                parentId: parentId,
                parentEmail: parentEmail,
                orderDate: orderDate,
                deliveryDate: deliveryDate,
                status: lunchOrderStatus,
                notes: notes
            )
            
            lunchOrders.append(lunchOrder)
        }
        
        return lunchOrders.sorted {
            $0.orderDate > $1.orderDate
        }
    }
    
    // MARK: - Parent Order History

    func loadOrders(forParentId parentId: String) async throws -> [LunchOrder] {
        let snapshot = try await db
            .collection("orders")
            .whereField("parentId", isEqualTo: parentId)
            .getDocuments()

        return try makeLunchOrders(from: snapshot.documents)
    }
    
    // MARK: - Live Orders
    
    func listenForOrderChanges(
        onChange: @escaping ([LunchOrder]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        
        db.collection("orders")
            .addSnapshotListener { [weak self] snapshot, error in
                
                if let error {
                    Task { @MainActor in
                        onError(error)
                    }
                    return
                }
                
                guard let self,
                      let snapshot else {
                    return
                }
                
                Task { @MainActor in
                    do {
                        let orders = try self.makeLunchOrders(
                            from: snapshot.documents
                        )
                        
                        onChange(orders)
                    } catch {
                        onError(error)
                    }
                }
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
    
    
    
    // MARK: - Item Refund
    
    func refundOrderItems(
        orderId: String,
        refundRequestId: String,
        items: [(itemId: String, quantity: Int)]
    ) async throws -> [String: Any] {
        
        let functions = Functions.functions(
            region: "australia-southeast1"
        )
        
        let refundItems: [[String: Any]] =
        items.map { item in
            [
                "itemId": item.itemId,
                "quantity": item.quantity
            ]
        }
        
        let result = try await functions
            .httpsCallable("refundLunchOrderItems")
            .call([
                "orderId": orderId,
                "refundRequestId": refundRequestId,
                "items": refundItems
            ])
        
        guard let data =
                result.data as? [String: Any] else {
            throw NSError(
                domain: "LunchBoxManager",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase returned an invalid refund response."
                ]
            )
        }
        
        return data
    }
}
