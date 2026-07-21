import Foundation
import PDFKit

/// A generated class packing list PDF for one school.
struct ClassPackingListReport: Identifiable {
    let id: UUID
    var schoolName: String
    var document: PDFDocument

    init(id: UUID = UUID(), schoolName: String, document: PDFDocument) {
        self.id = id
        self.schoolName = schoolName
        self.document = document
    }
}
