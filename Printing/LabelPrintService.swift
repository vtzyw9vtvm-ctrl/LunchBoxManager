import AppKit
import PDFKit

@MainActor
final class LabelPrintService {

@discardableResult
func printLabels(
    document: PDFDocument,
    jobTitle: String = "Lunch Labels"
) -> Bool {

    guard document.pageCount > 0 else {
        return false
    }

    let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo

    let labelSize = LabelGenerationService.labelSize

    printInfo.paperSize = labelSize

    printInfo.leftMargin = 0
    printInfo.rightMargin = 0
    printInfo.topMargin = 0
    printInfo.bottomMargin = 0

    printInfo.horizontalPagination = .fit
    printInfo.verticalPagination = .fit

    printInfo.isHorizontallyCentered = false
    printInfo.isVerticallyCentered = false

    // Always default label jobs to one copy
    printInfo.dictionary()[NSPrintInfo.AttributeKey.copies] = 1

    let printView = LabelPDFPrintView(
        document: document,
        pageSize: labelSize
    )

    let operation = NSPrintOperation(
        view: printView,
        printInfo: printInfo
    )

    operation.jobTitle = jobTitle
    operation.showsPrintPanel = true
    operation.showsProgressPanel = true

    return operation.run()
}

// MARK: - PDF Printing View

private final class LabelPDFPrintView: NSView {

    private let document: PDFDocument
    private let pageSize: NSSize

    init(
        document: PDFDocument,
        pageSize: NSSize
    ) {

        self.document = document
        self.pageSize = pageSize

        let height = pageSize.height * CGFloat(document.pageCount)

        super.init(
            frame: NSRect(
                x: 0,
                y: 0,
                width: pageSize.width,
                height: height
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        true
    }

    override func knowsPageRange(
        _ range: NSRangePointer
    ) -> Bool {

        range.pointee = NSRange(
            location: 1,
            length: document.pageCount
        )

        return true
    }

    override func rectForPage(
        _ page: Int
    ) -> NSRect {

        NSRect(
            x: 0,
            y: CGFloat(page - 1) * pageSize.height,
            width: pageSize.width,
            height: pageSize.height
        )
    }

    override func draw(
        _ dirtyRect: NSRect
    ) {

        let pageIndex = Int(
            floor(dirtyRect.minY / pageSize.height)
        )

        guard
            pageIndex >= 0,
            pageIndex < document.pageCount,
            let page = document.page(at: pageIndex)
        else {
            return
        }

        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()

        // Move drawing into the current label's position
        let pageOriginY = CGFloat(pageIndex) * pageSize.height

        context.translateBy(
            x: 0,
            y: pageOriginY + pageSize.height
        )

        context.scaleBy(
            x: 1,
            y: -1
        )

        page.draw(
            with: .mediaBox,
            to: context
        )

        context.restoreGState()
    }
}
}
