import Foundation
import PDFKit

/// A generated pasta preparation PDF combining all schools.
struct PastaPreparationReport: Identifiable {
    let id: UUID
    var reportName: String
    var document: PDFDocument

    init(id: UUID = UUID(), reportName: String, document: PDFDocument) {
        self.id = id
        self.reportName = reportName
        self.document = document
    }
}
