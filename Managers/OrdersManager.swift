import Foundation
import Observation

@MainActor
@Observable
final class OrdersManager {

    // MARK: - Storage

    private let storageKey = "LunchBoxManager.Orders"


    // MARK: - Orders

    private(set) var orders: [LunchOrder] = []


    // MARK: - Initialisation

    init() {

        if let savedOrders = loadOrders(),
           !savedOrders.isEmpty {

            orders = savedOrders

        } else {

            // Temporary sample data while developing.
            orders = SampleDataService()
                .makeSampleImport()
                .orders

            saveOrders()
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
