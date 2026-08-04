import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

/// Coordinates CSV import, sample data loading, and dashboard state.
@MainActor
@Observable
final class ImportViewModel {
    private let importService: CSVImportService
    private let sampleDataService: SampleDataService

    private(set) var recentImports: [ImportSession] = []
    private(set) var importedOrders: [LunchOrder] = []
    private(set) var issues: [CSVImportIssue] = []
    private(set) var discoveredColumnNames: [String] = []
    private(set) var headerDebugMessage: String?
    private(set) var importCompleteMessage: String?
    private(set) var isImporting = false
    private(set) var errorMessage: String?

    init(
        importService: CSVImportService? = nil,
        sampleDataService: SampleDataService? = nil
    ) {
        self.importService = importService ?? CSVImportService()
        self.sampleDataService = sampleDataService ?? SampleDataService()
    }

    var latestImport: ImportSession? {
        recentImports.first
    }

    var lastImportDate: Date? {
        latestImport?.importDate
    }

    var totalOrders: Int {
        importedOrders.count
    }

    var totalStudents: Int {
        importedOrders.reduce(0) { $0 + $1.studentOrders.count }
    }

    var totalClasses: Int {
        Set(importedOrders.flatMap { $0.studentOrders.compactMap(\.schoolClass?.id) }).count
    }

    var totalSchools: Int {
        Set(importedOrders.filter { !$0.school.name.isEmpty }.map(\.school.id)).count
    }

    func chooseAndImportCSVFile() async {
        guard let fileURL = chooseCSVFile() else { return }
        await importCSVFile(from: fileURL)
    }

    func importCSVFile(from fileURL: URL) async {
        isImporting = true
        errorMessage = nil
        headerDebugMessage = nil
        importCompleteMessage = nil
        discoveredColumnNames = []
        issues = []

        do {
            let result = try await importService.importOrders(from: fileURL)
            apply(result)
        } catch {
            errorMessage = error.localizedDescription
        }

        isImporting = false
    }

    func loadSampleData() {
        errorMessage = nil
        importCompleteMessage = nil
        apply(sampleDataService.makeSampleImport())
    }

    func dismissImportError() {
        errorMessage = nil
    }

    func dismissHeaderDebugMessage() {
        headerDebugMessage = nil
    }

    func dismissImportCompleteMessage() {
        importCompleteMessage = nil
    }

    private func formatHeaderDebugMessage(filename: String, headers: [String]) -> String {
        let columnList = headers.enumerated()
            .map { index, header in "\(index + 1). \(header.isEmpty ? "<empty>" : header)" }
            .joined(separator: "\n")
        return "Found \(headers.count) columns in \(filename):\n\n\(columnList)"
    }

    private func printHeaderDebugOutput(filename: String, headers: [String]) {
        print("Wix CSV header debug for \(filename):")
        for (index, header) in headers.enumerated() {
            print("\(index + 1). \(header.isEmpty ? "<empty>" : header)")
        }
    }

    private func apply(_ result: CSVImportResult) {
        importedOrders = result.orders
        recentImports.insert(result.session, at: 0)
        issues = result.issues
        importCompleteMessage = formatImportCompleteMessage(result)
        print(
            "ImportViewModel stored counts: "
                + "orders=\(totalOrders), "
                + "students=\(totalStudents), "
                + "classes=\(totalClasses), "
                + "schools=\(totalSchools)"
        )
    }

    private func formatImportCompleteMessage(_ result: CSVImportResult) -> String {
        """
        Orders (Wix): \(result.session.totalOrders)
        Student Lunches: \(result.session.totalStudents)
        Schools: \(result.session.totalSchools)
        Classes: \(result.session.totalClasses)
        Menu Items: \(result.summary.totalMenuItems)

        Warnings:
        - \(result.summary.capitalisationCorrections) student name capitalisation corrected
        - \(result.summary.duplicateClasses) duplicate classes
        - \(result.summary.skippedRows) skipped rows

        Ready to generate labels
        """
    }

    private func chooseCSVFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Import Orders"
        panel.prompt = "Import"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
