import AppKit
import Foundation
import PDFKit

/// Shared A4 portrait PDF renderer for operational reports.
final class ReportPDFRenderer {
    static let a4PortraitSize = CGSize(width: 595.2, height: 841.8)

    let context: CGContext
    let pageRect: CGRect
    let contentRect: CGRect
    private let data: NSMutableData
    private(set) var y: CGFloat = 0

    init?(margin: CGFloat = 36) {
        data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data) else { return nil }

        var mediaBox = CGRect(origin: .zero, size: Self.a4PortraitSize)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        self.context = context
        self.pageRect = mediaBox
        self.contentRect = mediaBox.insetBy(dx: margin, dy: margin)
    }

    func beginPage() {
        context.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        NSColor.white.setFill()
        pageRect.fill()
        y = contentRect.maxY
    }

    func endPage() {
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
    }

    func finish() -> PDFDocument {
        context.closePDF()
        return PDFDocument(data: data as Data) ?? PDFDocument()
    }

    func moveDown(_ amount: CGFloat) {
        y -= amount
    }

    func setY(_ value: CGFloat) {
        y = value
    }

    @discardableResult
    func drawText(
        _ text: String,
        font: NSFont,
        color: NSColor = .labelColor,
        alignment: NSTextAlignment = .left,
        rect: CGRect
    ) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        NSString(string: text).draw(in: rect, withAttributes: attributes)
        return rect.minY
    }

    func drawDivider(y: CGFloat, x: CGFloat? = nil, width: CGFloat? = nil, color: NSColor = .separatorColor) {
        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 0.75
        let startX = x ?? contentRect.minX
        let lineWidth = width ?? contentRect.width
        path.move(to: CGPoint(x: startX, y: y))
        path.line(to: CGPoint(x: startX + lineWidth, y: y))
        path.stroke()
    }
}
