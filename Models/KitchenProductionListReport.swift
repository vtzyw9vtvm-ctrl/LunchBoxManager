import Foundation
import PDFKit

/// A generated kitchen production list PDF for one school.
struct KitchenProductionListReport: Identifiable {
    let id: UUID
    var schoolName: String
    var document: PDFDocument

    init(id: UUID = UUID(), schoolName: String, document: PDFDocument) {
        self.id = id
        self.schoolName = schoolName
        self.document = document
    }
}
