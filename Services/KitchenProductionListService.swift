import AppKit
import Foundation
import PDFKit

/// Generates per-school kitchen production list PDFs grouped by menu item.
struct KitchenProductionListService {
    private let drinkNames = [
        "Boost Juice",
        "Iced Tea - 600ml",
        "Nippy's Milk - 375ml",
        "Presha Fruit Juice",
        "Just Juice Box - 200ml",
        "Bottled Water - 600ml"
    ]

    private let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMM yyyy"
        return formatter
    }()

    func makeReports(from orders: [LunchOrder], date: Date = Date()) -> [KitchenProductionListReport] {
        Dictionary(grouping: orders, by: { displaySchoolName($0.school.name) })
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { schoolName, schoolOrders in
                KitchenProductionListReport(
                    schoolName: schoolName,
                    document: makeDocument(schoolName: schoolName, orders: schoolOrders, date: date)
                )
            }
    }

    private func makeDocument(schoolName: String, orders: [LunchOrder], date: Date) -> PDFDocument {
        guard let renderer = ReportPDFRenderer() else { return PDFDocument() }
        let sections = makeSections(from: orders)
        let statistics = ProductionStatistics(
            totalOrders: orders.count,
            totalStudents: orders.reduce(0) { $0 + $1.studentOrders.count }
        )

        renderer.beginPage()
        drawPageHeader(schoolName: schoolName, date: date, statistics: statistics, renderer: renderer)
        drawTableHeader(renderer: renderer)

        for section in sections {
            draw(section, renderer: renderer, schoolName: schoolName, date: date, statistics: statistics)
        }

        renderer.endPage()
        return renderer.finish()
    }

    private func makeSections(from orders: [LunchOrder]) -> [ProductionSection] {
        var rowsByItem: [String: [ProductionRow]] = [:]
        var displayNameByItem: [String: String] = [:]

        for order in orders {
            for studentOrder in order.studentOrders {
                for item in studentOrder.items {
                    let itemName = productionItemName(for: item)
                    let itemKey = itemName.normalizedProductionText
                    displayNameByItem[itemKey] = itemName
                    rowsByItem[itemKey, default: []].append(
                        ProductionRow(
                            orderNumber: order.orderNumber,
                            studentName: displayStudentName(studentOrder.student.fullName),
                            className: displayClassName(studentOrder.schoolClass?.name ?? ""),
                            quantity: item.quantity,
                            instructions: productionInstructions(for: item)
                        )
                    )
                }
            }
        }

        return rowsByItem.map { itemKey, rows in
            let sortedRows = rows.sorted {
                $0.studentName.localizedStandardCompare($1.studentName) == .orderedAscending
            }
            return ProductionSection(
                itemName: displayNameByItem[itemKey] ?? "Unnamed Item",
                totalQuantity: rows.reduce(0) { $0 + $1.quantity },
                rows: sortedRows
            )
        }
        .sorted { $0.itemName.localizedStandardCompare($1.itemName) == .orderedAscending }
    }

    private func draw(
        _ section: ProductionSection,
        renderer: ReportPDFRenderer,
        schoolName: String,
        date: Date,
        statistics: ProductionStatistics
    ) {
        let headingHeight: CGFloat = 21
        let minimumRowsWithHeading = min(section.rows.count, 3)
        let minimumSectionHeight = headingHeight + CGFloat(minimumRowsWithHeading) * ProductionRow.minimumHeight

        if renderer.y - minimumSectionHeight < renderer.contentRect.minY {
            beginContinuationPage(renderer: renderer, schoolName: schoolName, date: date, statistics: statistics)
        }

        drawSectionHeading(section, renderer: renderer)

        for row in section.rows {
            let rowHeight = height(for: row, renderer: renderer)
            if renderer.y - rowHeight < renderer.contentRect.minY {
                beginContinuationPage(renderer: renderer, schoolName: schoolName, date: date, statistics: statistics)
                drawSectionHeading(section, renderer: renderer, isContinuation: true)
            }

            draw(row, height: rowHeight, renderer: renderer)
        }

        renderer.moveDown(4)
    }

    private func beginContinuationPage(
        renderer: ReportPDFRenderer,
        schoolName: String,
        date: Date,
        statistics: ProductionStatistics
    ) {
        renderer.endPage()
        renderer.beginPage()
        drawPageHeader(schoolName: schoolName, date: date, statistics: statistics, renderer: renderer)
    }

    private func drawPageHeader(
        schoolName: String,
        date: Date,
        statistics: ProductionStatistics,
        renderer: ReportPDFRenderer
    ) {
        let contentRect = renderer.contentRect
        renderer.setY(
            renderer.drawText(
                schoolName,
                font: .boldSystemFont(ofSize: 24),
                rect: CGRect(x: contentRect.minX, y: renderer.y - 32, width: contentRect.width, height: 32)
            )
        )
        renderer.moveDown(4)
        renderer.setY(
            renderer.drawText(
                reportDateFormatter.string(from: date),
                font: .systemFont(ofSize: 11),
                color: .secondaryLabelColor,
                rect: CGRect(x: contentRect.minX, y: renderer.y - 16, width: contentRect.width, height: 16)
            )
        )
        renderer.moveDown(8)
        renderer.setY(
            renderer.drawText(
                "Total Orders: \(statistics.totalOrders)    Total Students: \(statistics.totalStudents)",
                font: .boldSystemFont(ofSize: 11),
                rect: CGRect(x: contentRect.minX, y: renderer.y - 16, width: contentRect.width, height: 16)
            )
        )
        renderer.moveDown(8)
        renderer.drawDivider(y: renderer.y)
        renderer.moveDown(10)
    }

    private func drawSectionHeading(
        _ section: ProductionSection,
        renderer: ReportPDFRenderer,
        isContinuation: Bool = false
    ) {
        let contentRect = renderer.contentRect
        let rect = CGRect(x: contentRect.minX, y: renderer.y - 18, width: contentRect.width, height: 18)
        NSColor.controlBackgroundColor.setFill()
        rect.fill()

        let checkboxFont = NSFont.systemFont(ofSize: 17)
        let headingFont = NSFont.boldSystemFont(ofSize: 13)
        let title = "\(section.itemName.uppercased()) — \(section.totalQuantity)" + (isContinuation ? " CONTINUED" : "")
        renderer.drawText(
            "☐",
            font: checkboxFont,
            rect: CGRect(x: rect.minX, y: rect.minY, width: 18, height: rect.height)
        )
        renderer.drawText(
            title,
            font: headingFont,
            rect: CGRect(x: rect.minX + 20, y: rect.minY + 2, width: rect.width - 28, height: rect.height - 4)
        )
        renderer.moveDown(20)
    }

    private func drawTableHeader(renderer: ReportPDFRenderer) {
        let columns = tableColumns(in: renderer.contentRect)
        let y = renderer.y - 12
        let font = NSFont.boldSystemFont(ofSize: 8.5)
        renderer.drawText("Order #", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.orderNumber.minX, y: y, width: columns.orderNumber.width, height: 12))
        renderer.drawText("Student Name", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.student.minX, y: y, width: columns.student.width, height: 12))
        renderer.drawText("Class", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.className.minX, y: y, width: columns.className.width, height: 12))
        renderer.drawText("Qty", font: font, color: .secondaryLabelColor, alignment: .center, rect: CGRect(x: columns.quantity.minX, y: y, width: columns.quantity.width, height: 12))
        renderer.drawText("Extras", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.instructions.minX, y: y, width: columns.instructions.width, height: 12))
        renderer.moveDown(14)
        renderer.drawDivider(y: renderer.y)
        renderer.moveDown(6)
    }

    private func draw(_ row: ProductionRow, height: CGFloat, renderer: ReportPDFRenderer) {
        let columns = tableColumns(in: renderer.contentRect)
        let y = renderer.y - height + 1.5
        let textHeight = height - 2.5
        let font = NSFont.systemFont(ofSize: 7.5)
        let quantityFont = NSFont.boldSystemFont(ofSize: 8)
        let orderFont = NSFont.boldSystemFont(ofSize: 7.5)

        renderer.drawText(row.orderNumber, font: orderFont, rect: CGRect(x: columns.orderNumber.minX, y: y, width: columns.orderNumber.width, height: textHeight))
        renderer.drawText(row.studentName, font: font, rect: CGRect(x: columns.student.minX, y: y, width: columns.student.width, height: textHeight))
        renderer.drawText(row.className, font: font, rect: CGRect(x: columns.className.minX, y: y, width: columns.className.width, height: textHeight))
        renderer.drawText("\(row.quantity)", font: quantityFont, alignment: .center, rect: CGRect(x: columns.quantity.minX, y: y, width: columns.quantity.width, height: textHeight))
        drawWrappedText(
            row.instructions,
            font: font,
            rect: CGRect(x: columns.instructions.minX, y: y, width: columns.instructions.width, height: textHeight)
        )
        renderer.drawDivider(y: renderer.y - height, color: .separatorColor.withAlphaComponent(0.45))
        renderer.moveDown(height)
    }

    private func height(for row: ProductionRow, renderer: ReportPDFRenderer) -> CGFloat {
        let columns = tableColumns(in: renderer.contentRect)
        let instructionHeight = measuredHeight(row.instructions, font: .systemFont(ofSize: 7.5), width: columns.instructions.width)
        return max(ProductionRow.minimumHeight, ceil(instructionHeight) + 3.5)
    }

    private func tableColumns(in contentRect: CGRect) -> ProductionTableColumns {
        let orderWidth: CGFloat = 48
        let studentWidth: CGFloat = 138
        let classWidth: CGFloat = 62
        let quantityWidth: CGFloat = 30
        let gap: CGFloat = 8
        let studentX = contentRect.minX + orderWidth + gap
        let classX = studentX + studentWidth + gap
        let quantityX = classX + classWidth + gap
        let instructionsX = quantityX + quantityWidth + gap
        return ProductionTableColumns(
            orderNumber: CGRect(x: contentRect.minX, y: 0, width: orderWidth, height: 0),
            student: CGRect(x: studentX, y: 0, width: studentWidth, height: 0),
            className: CGRect(x: classX, y: 0, width: classWidth, height: 0),
            quantity: CGRect(x: quantityX, y: 0, width: quantityWidth, height: 0),
            instructions: CGRect(x: instructionsX, y: 0, width: contentRect.maxX - instructionsX, height: 0)
        )
    }

    private func measuredHeight(_ text: String, font: NSFont, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return ProductionRow.minimumHeight - 7 }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let rect = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: paragraphStyle]
        )
        return rect.height
    }

    private func drawWrappedText(_ text: String, font: NSFont, color: NSColor = .labelColor, rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        NSString(string: text).draw(in: rect, withAttributes: attributes)
    }

    private func productionItemName(for item: MenuItem) -> String {
        let normalizedName = item.name.normalizedProductionText
        if let drinkName = drinkNames.first(where: { normalizedName.contains($0.normalizedProductionText) }) {
            return drinkName
        }

        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unnamed Item" : trimmedName
    }

    private func productionInstructions(for item: MenuItem) -> String {
        var details = item.variants.compactMap(cleanExtrasText)
        if let notes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            if let cleanedNotes = cleanExtrasText(notes) {
                details.append(cleanedNotes)
            }
        }

        return details
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
    }

    private func cleanExtrasText(_ text: String) -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil }

        let cleanedText = trimmedText.replacingOccurrences(
            of: #"^special instructions:?\s*"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleanedText.isEmpty ? nil : cleanedText
    }

    private func displaySchoolName(_ schoolName: String) -> String {
        let trimmedName = schoolName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unknown School" : trimmedName
    }

    private func displayStudentName(_ studentName: String) -> String {
        let trimmedName = studentName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unnamed Student" : trimmedName
    }

    private func displayClassName(_ className: String) -> String {
        let trimmedName = className.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unassigned" : trimmedName
    }
}

private struct ProductionStatistics {
    var totalOrders: Int
    var totalStudents: Int
}

private struct ProductionSection {
    var itemName: String
    var totalQuantity: Int
    var rows: [ProductionRow]
}

private struct ProductionRow {
    static let minimumHeight: CGFloat = 12

    var orderNumber: String
    var studentName: String
    var className: String
    var quantity: Int
    var instructions: String
}

private struct ProductionTableColumns {
    var orderNumber: CGRect
    var student: CGRect
    var className: CGRect
    var quantity: CGRect
    var instructions: CGRect
}

private extension String {
    var normalizedProductionText: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
