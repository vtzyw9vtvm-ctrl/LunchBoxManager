import Foundation
import Observation
import PDFKit

/// Coordinates label generation and preview state.
@MainActor
@Observable
final class LabelsViewModel {
    private let labelGenerationService: LabelGenerationService
    private(set) var orders: [LunchOrder]
    private(set) var hotLabels: [LunchLabel] = []
    private(set) var coldLabels: [LunchLabel] = []
    private(set) var previewDocument: PDFDocument?
    private(set) var previewLabels: [LunchLabel] = []
    private(set) var previewTitle = "Print Preview"
    private(set) var message: String?
    var isShowingPreview = false

    init(orders: [LunchOrder], labelGenerationService: LabelGenerationService? = nil) {
        self.orders = orders
        self.labelGenerationService = labelGenerationService ?? LabelGenerationService()
    }

    var hotLabelCount: Int {
        hotLabels.count
    }

    var coldLabelCount: Int {
        coldLabels.count
    }

    func updateOrders(_ orders: [LunchOrder]) {
        self.orders = orders
        hotLabels = []
        coldLabels = []
        previewDocument = nil
        previewLabels = []
        previewTitle = "Print Preview"
        isShowingPreview = false
        message = nil
    }

    func generateHotLabels() {
        let labels = labelGenerationService.makeHotLabels(from: orders)
        hotLabels = labels
        showPreview(for: labels, title: "Hot Labels Preview", emptyMessage: "No hot labels were generated.")
    }

    func generateColdLabels() {
        let labels = labelGenerationService.makeColdLabels(from: orders)
        coldLabels = labels
        showPreview(for: labels, title: "Cold Labels Preview", emptyMessage: "No cold labels were generated.")
    }

    func dismissMessage() {
        message = nil
    }

    private func showPreview(for labels: [LunchLabel], title: String, emptyMessage: String) {
        previewTitle = title
        previewLabels = labels
        previewDocument = labelGenerationService.makePDFDocument(for: labels)

        if labels.isEmpty {
            message = emptyMessage
            isShowingPreview = false
        } else {
            message = nil
            isShowingPreview = true
        }
    }
}
