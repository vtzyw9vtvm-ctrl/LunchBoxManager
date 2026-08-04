import Foundation
import Observation
import PDFKit

/// Coordinates kitchen production report generation.
@MainActor
@Observable
final class ReportsViewModel {
    private let productionListService: KitchenProductionListService
    private let classPackingListService: ClassPackingListService
    private let pastaPreparationReportService: PastaPreparationReportService
    private(set) var productionListReports: [KitchenProductionListReport] = []
    private(set) var classPackingListReports: [ClassPackingListReport] = []
    private(set) var pastaPreparationReports: [PastaPreparationReport] = []
    private(set) var savedKitchenProductionReports: [SavedReport] = []
    private(set) var messageTitle = "Reports"
    private(set) var message: String?

    init(
        productionListService: KitchenProductionListService? = nil,
        classPackingListService: ClassPackingListService? = nil,
        pastaPreparationReportService: PastaPreparationReportService? = nil
    ) {
        self.productionListService = productionListService ?? KitchenProductionListService()
        self.classPackingListService = classPackingListService ?? ClassPackingListService()
        self.pastaPreparationReportService = pastaPreparationReportService ?? PastaPreparationReportService()
    }

    var reportCount: Int {
        productionListReports.count + classPackingListReports.count + pastaPreparationReports.count
    }

    func generateKitchenProductionLists(from orders: [LunchOrder]) {
        printOrdersDebugOutput(label: "generateKitchenProductionLists(from:)", orders: orders)
        productionListReports = productionListService.makeReports(from: orders)
        generatePastaPreparationReport(from: orders)

        let reports = kitchenProductionReportsForSaving()
        savedKitchenProductionReports = save(reports)

        if reports.isEmpty {
            messageTitle = "No Reports Generated"
            message = "Import orders before generating kitchen production lists."
        } else if savedKitchenProductionReports.count == reports.count {
            messageTitle = "Reports Generated"
            message = "Generated and saved \(reports.count) kitchen production reports, including Pasta Preparation Report."
        } else {
            messageTitle = "Reports Generated"
            message = "Generated \(reports.count) kitchen production reports, including Pasta Preparation Report. \(savedKitchenProductionReports.count) were saved successfully."
        }
    }

    func generateClassPackingLists(from orders: [LunchOrder]) {
        classPackingListReports = classPackingListService.makeReports(from: orders)
        messageTitle = classPackingListReports.isEmpty ? "No Reports Generated" : "Reports Generated"
        message = classPackingListReports.isEmpty ? "Import orders before generating class packing lists." : "Generated \(classPackingListReports.count) class packing reports."
    }

    func dismissMessage() {
        message = nil
    }

    private func generatePastaPreparationReport(from orders: [LunchOrder]) {
        printOrdersDebugOutput(label: "generatePastaPreparationReport(from:)", orders: orders)
        pastaPreparationReports = pastaPreparationReportService.makeReports(from: orders)
    }

    private func printOrdersDebugOutput(label: String, orders: [LunchOrder]) {
        print("ReportsViewModel debug - \(label)")
        print("orders.count: \(orders.count)")
        print("first order number: \(orders.first?.orderNumber ?? "none")")
        print("first menu item name: \(orders.first?.studentOrders.first?.items.first?.name ?? "none")")
    }

    private func kitchenProductionReportsForSaving() -> [SavableReport] {
        productionListReports.map { report in
            SavableReport(
                filename: "\(sanitizedFilename(report.schoolName)) Kitchen Production.pdf",
                document: report.document
            )
        } + pastaPreparationReports.map { report in
            SavableReport(
                filename: "\(sanitizedFilename(report.reportName)).pdf",
                document: report.document
            )
        }
    }

    private func save(_ reports: [SavableReport]) -> [SavedReport] {
        guard !reports.isEmpty else { return [] }

        let fileManager = FileManager.default
        let baseDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let reportsDirectory = baseDirectory.appendingPathComponent("School Lunch Manager Reports", isDirectory: true)

        do {
            try fileManager.createDirectory(at: reportsDirectory, withIntermediateDirectories: true)
        } catch {
            return []
        }

        return reports.compactMap { report in
            let url = reportsDirectory.appendingPathComponent(report.filename)
            guard report.document.write(to: url) else { return nil }
            return SavedReport(filename: report.filename, url: url, document: report.document)
        }
    }

    private func sanitizedFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
            .union(.newlines)
            .union(.controlCharacters)
        let sanitized = filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitized.isEmpty ? "Report" : sanitized
    }
}

struct SavedReport: Identifiable {
    let id = UUID()
    var filename: String
    var url: URL
    var document: PDFDocument
}

private struct SavableReport {
    var filename: String
    var document: PDFDocument
}
