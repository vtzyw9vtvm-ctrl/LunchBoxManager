import PDFKit
import SwiftUI

/// Displays a PDFKit document inside SwiftUI.
struct PDFPreviewView: NSViewRepresentable {
    var document: PDFDocument
    var highlightedPageIndex: Int?
    var highlightToken: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = .windowBackgroundColor
        pdfView.document = document
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
        }

        guard context.coordinator.lastHighlightToken != highlightToken else { return }
        context.coordinator.lastHighlightToken = highlightToken

        guard let highlightedPageIndex,
              let page = document.page(at: highlightedPageIndex) else { return }

        pdfView.go(to: page)
        context.coordinator.highlight(page: page)
    }

    final class Coordinator {
        var lastHighlightToken = 0
        private weak var highlightedPage: PDFPage?
        private weak var highlightAnnotation: PDFAnnotation?

        func highlight(page: PDFPage) {
            clearHighlight()

            let bounds = page.bounds(for: .mediaBox)
            let annotation = PDFAnnotation(bounds: bounds.insetBy(dx: 2, dy: 2), forType: .square, withProperties: nil)
            annotation.color = NSColor.systemYellow.withAlphaComponent(0.8)
            annotation.interiorColor = NSColor.systemYellow.withAlphaComponent(0.16)
            annotation.border = PDFBorder()
            annotation.border?.lineWidth = 2
            page.addAnnotation(annotation)

            highlightedPage = page
            highlightAnnotation = annotation

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.clearHighlight()
            }
        }

        private func clearHighlight() {
            if let highlightedPage, let highlightAnnotation {
                highlightedPage.removeAnnotation(highlightAnnotation)
            }
            highlightedPage = nil
            highlightAnnotation = nil
        }
    }
}
