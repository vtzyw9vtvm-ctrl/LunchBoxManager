import Foundation
import Observation

/// Coordinates kitchen run sheet report generation.
@MainActor
@Observable
final class ReportsViewModel {
    private let service: KitchenRunSheetService
    private(set) var reports: [KitchenRunSheetReport] = []
    private(set) var message: String?

    init(service: KitchenRunSheetService? = nil) {
        self.service = service ?? KitchenRunSheetService()
    }

    var reportCount: Int {
        reports.count
    }

    func generateKitchenRunSheets(from orders: [LunchOrder]) {
        reports = service.makeReports(from: orders)
        message = reports.isEmpty ? "Import orders before generating kitchen run sheets." : nil
    }

    func dismissMessage() {
        message = nil
    }
}
