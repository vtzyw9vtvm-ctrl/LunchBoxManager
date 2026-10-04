import Foundation
import Observation
import FirebaseFirestore

@MainActor
@Observable
final class OrdersManager {

    // MARK: - Storage

    private let storageKey = "LunchBoxManager.Orders"
    private let firebaseOrderService = FirebaseOrderService()
    private let db = Firestore.firestore()
    private var ordersListener: ListenerRegistration?
    // Temporary development setting.
    // Change this to false when real parent-app orders are connected.
    private let useSampleData = false


    // MARK: - Orders

    private(set) var orders: [LunchOrder] = []


    // MARK: - Initialisation

    init() {

        if let savedOrders = loadOrders(),
           !savedOrders.isEmpty {

            orders = savedOrders

        } else if useSampleData {

            orders = SampleDataService()
                .makeSampleImport()
                .orders

            saveOrders()

        } else {

            orders = []
        }

        startFirebaseListener()
    }
    
    private func makeLunchOrder(
        from document: QueryDocumentSnapshot
    ) -> LunchOrder? {

        let data = document.data()

        // MARK: - Delivery Date

        guard let deliveryTimestamp = data["deliveryDate"] as? Timestamp else {
            print("⚠️ Missing deliveryDate:", document.documentID)
            return nil
        }

        let deliveryDate = deliveryTimestamp.dateValue()

        // MARK: - School

        let schoolName = data["school"] as? String ?? "Unknown School"

        let schoolShortName: String

        switch schoolName.lowercased() {
        case let name where name.contains("christ"):
            schoolShortName = "CTP"

        case let name where name.contains("burnside"):
            schoolShortName = "BPS"

        default:
            schoolShortName = schoolName
        }

        let schoolID: UUID

        switch schoolShortName {
        case "CTP":
            schoolID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        case "BPS":
            schoolID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        default:
            schoolID = UUID()
        }

        let school = School(
            id: schoolID,
            name: schoolName,
            shortName: schoolShortName
        )
        // MARK: - Student

        let firstName = data["firstName"] as? String ?? ""
        let lastName = data["lastName"] as? String ?? ""

        let fallbackChildName =
            data["childName"] as? String ?? ""

        let student: Student

        if !firstName.isEmpty || !lastName.isEmpty {

            student = Student(
                firstName: firstName,
                lastName: lastName,
                allergies: data["foodAllergies"] as? String ?? ""
            )

        } else {

            let nameParts = fallbackChildName.split(
                separator: " ",
                maxSplits: 1
            )

            student = Student(
                firstName: nameParts.first.map(String.init) ?? fallbackChildName,
                lastName: nameParts.count > 1
                    ? String(nameParts[1])
                    : "",
                allergies: data["foodAllergies"] as? String ?? ""
            )
        }

        // MARK: - School Class

        let className = data["className"] as? String ?? ""
        let yearLevel = data["yearLevel"] as? String ?? ""

        let schoolClass: SchoolClass?

        if !className.isEmpty || !yearLevel.isEmpty {

            schoolClass = SchoolClass(
                name: className.isEmpty ? yearLevel : className,
                yearLevel: yearLevel,
                schoolID: school.id
            )

        } else {

            schoolClass = nil
        }

        // MARK: - Items

        let rawItems =
            data["items"] as? [[String: Any]] ?? []

        let items: [MenuItem] = rawItems.map { itemData in

            let rawOptions =
                itemData["selectedOptions"] as? [[String: Any]] ?? []

            let variants = rawOptions.compactMap {
                $0["name"] as? String
            }

            return MenuItem(
                firebaseOrderItemID:
                    itemData["id"] as? String,

                name:
                    itemData["name"] as? String
                    ?? "Unknown Item",

                category:
                    itemData["category"] as? String
                    ?? "",

                variants:
                    variants,

                quantity:
                    (itemData["quantity"] as? NSNumber)?
                        .intValue ?? 1,

                refundedQuantity:
                    (itemData["refundedQuantity"] as? NSNumber)?
                        .intValue ?? 0,

                refundedAmount:
                    (itemData["refundedAmount"] as? NSNumber)?
                        .doubleValue ?? 0,

                notes:
                    itemData["notes"] as? String,

                isHot:
                    itemData["isHot"] as? Bool
                    ?? false,

                isCold:
                    itemData["isCold"] as? Bool
                    ?? false,

                isGlutenFree:
                    itemData["isGlutenFree"] as? Bool
                    ?? false,

                isVegan:
                    itemData["isVegan"] as? Bool
                    ?? false,

                isVegetarian:
                    itemData["isVegetarian"] as? Bool
                    ?? false,

                isHalal:
                    itemData["isHalal"] as? Bool
                    ?? false
            )
        }

        // MARK: - Student Order

        let studentOrder = StudentOrder(
            student: student,
            schoolClass: schoolClass,
            items: items
        )

        // MARK: - Order Number

        let orderNumber: String

        if let number = data["orderNumber"] as? NSNumber {
            orderNumber = String(
                format: "%05d",
                number.intValue
            )
        } else {
            orderNumber =
                data["orderNumber"] as? String
                ?? document.documentID
        }

        // MARK: - Order Date

        let orderDate =
            (data["createdAt"] as? Timestamp)?
                .dateValue()
            ?? deliveryDate

        // MARK: - Status

        let statusString =
            data["status"] as? String ?? "new"

        let status =
            LunchOrderStatus(rawValue: statusString)
            ?? .new

        // MARK: - Lunch Order

        return LunchOrder(
            firebaseDocumentID: document.documentID,
            orderNumber: orderNumber,
            school: school,
            studentOrders: [studentOrder],
            parentId: data["parentId"] as? String,
            parentEmail: data["parentEmail"] as? String,
            orderDate: orderDate,
            deliveryDate: deliveryDate,
            status: status,
            notes: data["notes"] as? String
        )
    }

    // MARK: - Firebase Orders

    func startFirebaseListener() {
        ordersListener?.remove()

        ordersListener = firebaseOrderService.listenForOrderChanges(
            onChange: { [weak self] firebaseOrders in
                guard let self else { return }

                print(
                    "🔥 FIREBASE ORDERS RECEIVED:",
                    firebaseOrders.count
                )

                self.orders = firebaseOrders
                self.saveOrders()
            },
            onError: { error in
                print(
                    "❌ FIREBASE ORDERS ERROR:",
                    error.localizedDescription
                )
            }
        )
    }
    // MARK: - Replace Orders

    func replaceOrders(with newOrders: [LunchOrder]) {

        orders = newOrders
        saveOrders()
    }


    // MARK: - Add Order

    func addOrder(_ order: LunchOrder) {

        orders.append(order)
        saveOrders()
    }


    // MARK: - Update Order

    func updateOrder(_ order: LunchOrder) {

        guard let index = orders.firstIndex(
            where: { $0.id == order.id }
        ) else {
            return
        }

        orders[index] = order
        saveOrders()
    }


    // MARK: - Remove Order

    func removeOrder(id: UUID) {

        orders.removeAll {
            $0.id == id
        }

        saveOrders()
    }

    // MARK: - Sync Incoming Orders

    func syncIncomingOrders(_ incomingOrders: [LunchOrder]) {
        
        // Firebase is now the source of truth.
        // Remove old sample/local orders that have no Firebase document ID.
        orders.removeAll { order in
            order.firebaseDocumentID == nil
        }

        for incomingOrder in incomingOrders {

            let existingIndex = orders.firstIndex { existingOrder in

                if let incomingFirebaseID = incomingOrder.firebaseDocumentID,
                   let existingFirebaseID = existingOrder.firebaseDocumentID {

                    return incomingFirebaseID == existingFirebaseID
                }

                return existingOrder.id == incomingOrder.id
            }

            if let existingIndex {

                // This order already exists.
                // Preserve our local printing status.
                var updatedOrder = incomingOrder

                for studentIndex in updatedOrder.studentOrders.indices {

                    let incomingStudentOrderID =
                        updatedOrder.studentOrders[studentIndex].id

                    if let existingStudentOrder =
                        orders[existingIndex]
                            .studentOrders
                            .first(where: {
                                $0.id == incomingStudentOrderID
                            }) {

                        updatedOrder
                            .studentOrders[studentIndex]
                            .hotLabelPrinted =
                                existingStudentOrder.hotLabelPrinted

                        updatedOrder
                            .studentOrders[studentIndex]
                            .coldLabelPrinted =
                                existingStudentOrder.coldLabelPrinted
                    }
                }

                orders[existingIndex] = updatedOrder

            } else {

                // Completely new order.
                orders.append(incomingOrder)
            }
        }
        // Remove duplicate Firebase orders that may have been
        // saved locally during earlier development.
        var seenFirebaseIDs = Set<String>()

        orders.removeAll { order in
            guard let firebaseID = order.firebaseDocumentID else {
                return false
            }

            if seenFirebaseIDs.contains(firebaseID) {
                return true
            }

            seenFirebaseIDs.insert(firebaseID)
            return false
        }
        saveOrders()
    }
    
    // MARK: - Save

    func saveOrders() {

        do {

            let data = try JSONEncoder()
                .encode(orders)

            UserDefaults.standard.set(
                data,
                forKey: storageKey
            )

        } catch {

            print(
                "Failed to save orders:",
                error
            )
        }
    }


    // MARK: - Load

    private func loadOrders() -> [LunchOrder]? {

        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return nil
        }

        do {

            return try JSONDecoder()
                .decode(
                    [LunchOrder].self,
                    from: data
                )

        } catch {

            print(
                "Failed to load orders:",
                error
            )

            return nil
        }
    }
}
