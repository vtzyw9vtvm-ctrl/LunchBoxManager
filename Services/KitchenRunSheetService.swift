import AppKit
import Foundation
import PDFKit

/// Generates A4 kitchen run sheets grouped by school.
struct KitchenRunSheetService {
    private static let a4PortraitSize = CGSize(width: 595.2, height: 841.8)
    private let coldItemConfiguration: ColdLabelItemConfiguration

    init(coldItemConfiguration: ColdLabelItemConfiguration? = nil) {
        self.coldItemConfiguration = coldItemConfiguration ?? .load()
    }

    func makeReports(from orders: [LunchOrder], date: Date = Date()) -> [KitchenRunSheetReport] {
        Dictionary(grouping: orders, by: { displaySchoolName($0.school.name) })
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { schoolName, schoolOrders in
                KitchenRunSheetReport(
                    schoolName: schoolName,
                    document: makeDocument(schoolName: schoolName, orders: schoolOrders, date: date)
                )
            }
    }

    private func makeDocument(schoolName: String, orders: [LunchOrder], date: Date) -> PDFDocument {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data) else { return PDFDocument() }

        var mediaBox = CGRect(origin: .zero, size: Self.a4PortraitSize)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return PDFDocument() }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        drawReport(schoolName: schoolName, orders: orders, date: date, context: context, pageRect: mediaBox)
        NSGraphicsContext.restoreGraphicsState()
        context.closePDF()

        return PDFDocument(data: data as Data) ?? PDFDocument()
    }

    private func drawReport(
        schoolName: String,
        orders: [LunchOrder],
        date: Date,
        context: CGContext,
        pageRect: CGRect
    ) {
        let classifiedItems = classifyItems(from: orders)
        let statistics = makeStatistics(orders: orders, classifiedItems: classifiedItems)
        let hotItems = groupedItems(classifiedItems.hot)
        let coldItems = groupedItems(classifiedItems.cold)
        let drinkItems = groupedDrinkItems(classifiedItems.drinks)

        context.beginPDFPage(nil)
        NSColor.white.setFill()
        pageRect.fill()

        let contentRect = pageRect.insetBy(dx: 36, dy: 36)
        let columnsTop = drawHeader(
            schoolName: schoolName,
            date: date,
            statistics: statistics,
            contentRect: contentRect
        )
        let gutter: CGFloat = 24
        let columnWidth = (contentRect.width - gutter) / 2
        let leftColumn = CGRect(
            x: contentRect.minX,
            y: contentRect.minY,
            width: columnWidth,
            height: columnsTop - contentRect.minY
        )
        let rightColumn = CGRect(
            x: contentRect.minX + columnWidth + gutter,
            y: contentRect.minY,
            width: columnWidth,
            height: columnsTop - contentRect.minY
        )

        drawColumn(sections: [ReportSection(title: "HOT FOOD", items: hotItems)], in: leftColumn)
        drawColumn(
            sections: [
                ReportSection(title: "COLD FOOD", items: coldItems),
                ReportSection(title: "DRINKS", items: drinkItems)
            ],
            in: rightColumn
        )

        context.endPDFPage()
    }

    private func drawHeader(
        schoolName: String,
        date: Date,
        statistics: ReportStatistics,
        contentRect: CGRect
    ) -> CGFloat {
        var y = contentRect.maxY
        drawText(schoolName, font: .boldSystemFont(ofSize: 24), rect: CGRect(x: contentRect.minX, y: y - 32, width: contentRect.width, height: 32))
        y -= 34

        drawText(
            date.formatted(date: .abbreviated, time: .omitted),
            font: .systemFont(ofSize: 11),
            color: .secondaryLabelColor,
            rect: CGRect(x: contentRect.minX, y: y - 16, width: contentRect.width, height: 16)
        )
        y -= 24

        let summary = "Orders: \(statistics.orders)    Students: \(statistics.students)    Hot Items: \(statistics.hotItems)    Cold Items: \(statistics.coldItems)    Drinks: \(statistics.drinks)"
        drawText(summary, font: .boldSystemFont(ofSize: 10.5), rect: CGRect(x: contentRect.minX, y: y - 16, width: contentRect.width, height: 16))
        y -= 22

        drawDivider(y: y, x: contentRect.minX, width: contentRect.width)
        return y - 18
    }

    private func drawColumn(sections: [ReportSection], in columnRect: CGRect) {
        var y = columnRect.maxY
        let minimumY = columnRect.minY

        for section in sections {
            guard y - 28 >= minimumY else { return }
            y = drawSectionTitle(section.title, y: y, columnRect: columnRect)

            for item in section.items {
                guard y - item.requiredHeight >= minimumY else { return }
                y = drawRunSheetItem(item, y: y, columnRect: columnRect)
            }

            y -= 14
        }
    }

    private func drawSectionTitle(_ title: String, y: CGFloat, columnRect: CGRect) -> CGFloat {
        drawText(title, font: .boldSystemFont(ofSize: 16), rect: CGRect(x: columnRect.minX, y: y - 22, width: columnRect.width, height: 22))
        drawDivider(y: y - 24, x: columnRect.minX, width: columnRect.width)
        return y - 34
    }

    private func drawRunSheetItem(_ item: RunSheetItem, y: CGFloat, columnRect: CGRect) -> CGFloat {
        let checkboxText = "☐"
        let quantityText = "\(item.quantity)"
        let checkboxFont = NSFont.systemFont(ofSize: 11)
        let quantityFont = NSFont.boldSystemFont(ofSize: 13)
        let itemFont = NSFont.systemFont(ofSize: 11)
        let checkboxWidth = measuredWidth(of: checkboxText, font: checkboxFont) + 6
        let quantityWidth = measuredWidth(of: quantityText, font: quantityFont) + 8
        let lineRect = CGRect(x: columnRect.minX, y: y - 16, width: columnRect.width, height: 16)

        drawText(
            checkboxText,
            font: checkboxFont,
            rect: CGRect(x: lineRect.minX, y: lineRect.minY, width: checkboxWidth, height: lineRect.height)
        )
        drawText(
            quantityText,
            font: quantityFont,
            rect: CGRect(x: lineRect.minX + checkboxWidth, y: lineRect.minY, width: quantityWidth, height: lineRect.height)
        )
        drawText(
            item.name,
            font: itemFont,
            rect: CGRect(
                x: lineRect.minX + checkboxWidth + quantityWidth,
                y: lineRect.minY,
                width: lineRect.width - checkboxWidth - quantityWidth,
                height: lineRect.height
            )
        )

        var nextY = y - 18
        for variant in item.variants {
            nextY = drawRunSheetVariant(variant, y: nextY, columnRect: columnRect)
        }

        return nextY
    }

    private func drawRunSheetVariant(_ variant: RunSheetVariant, y: CGFloat, columnRect: CGRect) -> CGFloat {
        let quantityText = "\(variant.quantity)"
        let quantityFont = NSFont.boldSystemFont(ofSize: 11)
        let variantFont = NSFont.systemFont(ofSize: 10)
        let indent: CGFloat = 24
        let quantityWidth = measuredWidth(of: quantityText, font: quantityFont) + 8
        let lineRect = CGRect(x: columnRect.minX + indent, y: y - 14, width: columnRect.width - indent, height: 14)

        drawText(
            quantityText,
            font: quantityFont,
            color: .secondaryLabelColor,
            rect: CGRect(x: lineRect.minX, y: lineRect.minY, width: quantityWidth, height: lineRect.height)
        )
        drawText(
            variant.name,
            font: variantFont,
            color: .secondaryLabelColor,
            rect: CGRect(
                x: lineRect.minX + quantityWidth,
                y: lineRect.minY,
                width: lineRect.width - quantityWidth,
                height: lineRect.height
            )
        )
        return y - 14
    }

    private func drawDivider(y: CGFloat, x: CGFloat, width: CGFloat) {
        NSColor.separatorColor.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 0.75
        path.move(to: CGPoint(x: x, y: y))
        path.line(to: CGPoint(x: x + width, y: y))
        path.stroke()
    }

    private func measuredWidth(of text: String, font: NSFont) -> CGFloat {
        NSString(string: text).size(withAttributes: [.font: font]).width
    }

    private func makeStatistics(orders: [LunchOrder], classifiedItems: ClassifiedItems) -> ReportStatistics {
        ReportStatistics(
            orders: orders.count,
            students: orders.reduce(0) { $0 + $1.studentOrders.count },
            hotItems: classifiedItems.hot.reduce(0) { $0 + $1.quantity },
            coldItems: classifiedItems.cold.reduce(0) { $0 + $1.quantity },
            drinks: classifiedItems.drinks.reduce(0) { $0 + $1.quantity }
        )
    }

    private func classifyItems(from orders: [LunchOrder]) -> ClassifiedItems {
        var hot: [MenuItem] = []
        var cold: [MenuItem] = []
        var drinks: [MenuItem] = []

        for item in orders.flatMap({ $0.studentOrders.flatMap(\.items) }) {
            if isDrink(item) {
                drinks.append(item)
            } else if isColdFood(item) {
                cold.append(item)
            } else {
                hot.append(item)
            }
        }

        return ClassifiedItems(hot: hot, cold: cold, drinks: drinks)
    }

    private func groupedItems(_ items: [MenuItem]) -> [RunSheetItem] {
        Dictionary(grouping: items, by: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) })
            .map { name, items in
                RunSheetItem(name: name.isEmpty ? "Unnamed Item" : name, quantity: items.reduce(0) { $0 + $1.quantity })
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func groupedDrinkItems(_ items: [MenuItem]) -> [RunSheetItem] {
        Dictionary(grouping: items, by: drinkDisplayName)
            .map { drinkName, items in
                RunSheetItem(
                    name: drinkName,
                    quantity: items.reduce(0) { $0 + $1.quantity },
                    variants: groupedDrinkVariants(items)
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func groupedDrinkVariants(_ items: [MenuItem]) -> [RunSheetVariant] {
        let variants = items.flatMap { item in
            item.variants
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { RunSheetVariant(name: $0, quantity: item.quantity) }
        }

        return Dictionary(grouping: variants, by: \.name)
            .map { name, variants in
                RunSheetVariant(name: name, quantity: variants.reduce(0) { $0 + $1.quantity })
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func isDrink(_ item: MenuItem) -> Bool {
        let normalizedName = item.name.normalizedReportText
        return normalizedDrinkNames.contains { normalizedName.contains($0) }
    }

    private func isColdFood(_ item: MenuItem) -> Bool {
        if item.isHot { return false }
        if item.isCold { return true }

        let normalizedName = item.name.normalizedReportText
        return coldItemConfiguration.coldItemNames
            .map(\.normalizedReportText)
            .contains { normalizedName.contains($0) }
    }

    private func displaySchoolName(_ schoolName: String) -> String {
        let trimmedName = schoolName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unknown School" : trimmedName
    }

    private var normalizedDrinkNames: [String] {
        drinkNames.map(\.normalizedReportText)
    }

    private var drinkNames: [String] {
        [
            "Boost Juice",
            "Iced Tea - 600ml",
            "Nippy's Milk - 375ml",
            "Presha Fruit Juice",
            "Just Juice Box - 200ml",
            "Bottled Water - 600ml"
        ]
    }

    private func drinkDisplayName(for item: MenuItem) -> String {
        let normalizedName = item.name.normalizedReportText
        if let drinkName = drinkNames.first(where: { normalizedName.contains($0.normalizedReportText) }) {
            return drinkName
        }

        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unnamed Drink" : trimmedName
    }

    @discardableResult
    private func drawText(
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
}

private struct ClassifiedItems {
    var hot: [MenuItem]
    var cold: [MenuItem]
    var drinks: [MenuItem]
}

private struct ReportSection {
    var title: String
    var items: [RunSheetItem]
}

private struct ReportStatistics {
    var orders: Int
    var students: Int
    var hotItems: Int
    var coldItems: Int
    var drinks: Int
}

private struct RunSheetItem {
    var name: String
    var quantity: Int
    var variants: [RunSheetVariant] = []

    var requiredHeight: CGFloat {
        18 + CGFloat(variants.count * 14)
    }
}

private struct RunSheetVariant {
    var name: String
    var quantity: Int
}

private extension String {
    var normalizedReportText: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
