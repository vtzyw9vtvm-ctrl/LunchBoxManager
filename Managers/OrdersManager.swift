import Foundation
import Observation

@MainActor
@Observable
final class OrdersManager {

    // MARK: - Storage

    private let storageKey = "LunchBoxManager.Orders"
    // Temporary development setting.
    // Change this to false when real parent-app orders are connected.
    private let useSampleData = true


    // MARK: - Orders

    private(set) var orders: [LunchOrder] = []


    // MARK: - Initialisation

    init() {

        if let savedOrders = loadOrders(),
           !savedOrders.isEmpty {

            orders = savedOrders
            return
        }

        if useSampleData {

            // Development only.
            orders = SampleDataService()
                .makeSampleImport()
                .orders

            saveOrders()

        } else {

            // Real app with no orders yet.
            orders = []
        }
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

        for incomingOrder in incomingOrders {

            if let existingIndex = orders.firstIndex(
                where: { $0.id == incomingOrder.id }
            ) {

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
