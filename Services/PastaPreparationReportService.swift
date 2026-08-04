import AppKit
import Foundation
import PDFKit

/// Generates one combined pasta preparation PDF grouped by pasta type.
struct PastaPreparationReportService {
    private let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMM yyyy"
        return formatter
    }()

    func makeReports(from orders: [LunchOrder], date: Date = Date()) -> [PastaPreparationReport] {
        print("******** PASTA REPORT SERVICE IS RUNNING ********")
        let sections = makeSections(from: orders)
        guard !sections.isEmpty else { return [] }

        return [
            PastaPreparationReport(
                reportName: "Pasta Preparation Report",
                document: makeDocument(sections: sections, date: date)
            )
        ]
    }

    private func makeDocument(sections: [PastaSection], date: Date) -> PDFDocument {
        guard let renderer = ReportPDFRenderer() else { return PDFDocument() }
        let statistics = PastaStatistics(
            totalOrders: Set(sections.flatMap { section in section.rows.map(\.orderNumber) }).count,
            totalStudents: Set(sections.flatMap { section in section.rows.map(\.studentOrderID) }).count
        )

        renderer.beginPage()
        drawPageHeader(date: date, statistics: statistics, renderer: renderer)
        drawTableHeader(renderer: renderer)

        for section in sections {
            draw(section, renderer: renderer, date: date, statistics: statistics)
        }

        renderer.endPage()
        return renderer.finish()
    }

    private func makeSections(from orders: [LunchOrder]) -> [PastaSection] {
        var rowsByItem: [String: [PastaRow]] = [:]
        var displayNameByItem: [String: String] = [:]
        var totalStudentOrdersProcessed = 0
        var totalMenuItemsProcessed = 0
        var matchedItemNames: [String] = []

        for order in orders {
            let schoolName = displaySchoolName(order.school.name)
            for studentOrder in order.studentOrders {
                totalStudentOrdersProcessed += 1
                for item in studentOrder.items {
                    totalMenuItemsProcessed += 1
                    guard isPastaItem(item) else { continue }

                    let itemName = pastaItemName(for: item)
                    matchedItemNames.append(itemName)
                    let itemKey = itemName.normalizedPastaPreparationText
                    displayNameByItem[itemKey] = itemName

                    let extras = pastaExtras(for: item)
                    rowsByItem[itemKey, default: []].append(
                        PastaRow(
                            studentOrderID: studentOrder.id,
                            orderNumber: order.orderNumber,
                            studentName: displayStudentName(studentOrder.student.fullName),
                            className: displayClassName(studentOrder.schoolClass?.name ?? ""),
                            schoolName: schoolName,
                            quantity: item.quantity,
                            extras: extras,
                            hasParmesan: hasParmesan(in: extras)
                        )
                    )
                }
            }
        }

        printPastaDebugOutput(
            totalOrdersProcessed: orders.count,
            totalStudentOrdersProcessed: totalStudentOrdersProcessed,
            totalMenuItemsProcessed: totalMenuItemsProcessed,
            matchedItemNames: matchedItemNames
        )

        return rowsByItem.map { itemKey, rows in
            let sortedRows = rows.sorted { first, second in
                first.schoolName.localizedStandardCompare(second.schoolName) == .orderedAscending
                    || (
                        first.schoolName.localizedStandardCompare(second.schoolName) == .orderedSame
                            && first.studentName.localizedStandardCompare(second.studentName) == .orderedAscending
                    )
            }

            return PastaSection(
                itemName: displayNameByItem[itemKey] ?? "Unnamed Item",
                totalQuantity: rows.reduce(0) { $0 + $1.quantity },
                parmesanYesQuantity: rows.filter(\.hasParmesan).reduce(0) { $0 + $1.quantity },
                parmesanNoQuantity: rows.filter { !$0.hasParmesan }.reduce(0) { $0 + $1.quantity },
                rows: sortedRows
            )
        }
        .sorted { $0.itemName.localizedStandardCompare($1.itemName) == .orderedAscending }
    }

    private func draw(
        _ section: PastaSection,
        renderer: ReportPDFRenderer,
        date: Date,
        statistics: PastaStatistics
    ) {
        let headingHeight: CGFloat = 37
        let minimumRowsWithHeading = min(section.rows.count, 3)
        let minimumSectionHeight = headingHeight + CGFloat(minimumRowsWithHeading) * PastaRow.minimumHeight

        if renderer.y - minimumSectionHeight < renderer.contentRect.minY {
            beginContinuationPage(renderer: renderer, date: date, statistics: statistics)
        }

        drawSectionHeading(section, renderer: renderer)

        for row in section.rows {
            let rowHeight = height(for: row, renderer: renderer)
            if renderer.y - rowHeight < renderer.contentRect.minY {
                beginContinuationPage(renderer: renderer, date: date, statistics: statistics)
                drawSectionHeading(section, renderer: renderer, isContinuation: true)
            }

            draw(row, height: rowHeight, renderer: renderer)
        }

        renderer.moveDown(4)
    }

    private func beginContinuationPage(
        renderer: ReportPDFRenderer,
        date: Date,
        statistics: PastaStatistics
    ) {
        renderer.endPage()
        renderer.beginPage()
        drawPageHeader(date: date, statistics: statistics, renderer: renderer)
    }

    private func drawPageHeader(
        date: Date,
        statistics: PastaStatistics,
        renderer: ReportPDFRenderer
    ) {
        let contentRect = renderer.contentRect
        renderer.setY(
            renderer.drawText(
                "Pasta Preparation Report",
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
        _ section: PastaSection,
        renderer: ReportPDFRenderer,
        isContinuation: Bool = false
    ) {
        let contentRect = renderer.contentRect
        let rect = CGRect(x: contentRect.minX, y: renderer.y - 34, width: contentRect.width, height: 34)
        NSColor.controlBackgroundColor.setFill()
        rect.fill()

        let checkboxFont = NSFont.systemFont(ofSize: 17)
        let headingFont = NSFont.boldSystemFont(ofSize: 13)
        let summaryFont = NSFont.systemFont(ofSize: 10)
        let title = "\(section.itemName.uppercased()) — \(section.totalQuantity)" + (isContinuation ? " CONTINUED" : "")
        let summary = "Parmesan Yes: \(section.parmesanYesQuantity)    No: \(section.parmesanNoQuantity)"

        renderer.drawText(
            "☐",
            font: checkboxFont,
            rect: CGRect(x: rect.minX, y: rect.maxY - 20, width: 18, height: 18)
        )
        renderer.drawText(
            title,
            font: headingFont,
            rect: CGRect(x: rect.minX + 20, y: rect.maxY - 18, width: rect.width - 28, height: 16)
        )
        renderer.drawText(
            summary,
            font: summaryFont,
            color: .secondaryLabelColor,
            rect: CGRect(x: rect.minX + 20, y: rect.minY + 4, width: rect.width - 28, height: 12)
        )
        renderer.moveDown(36)
    }

    private func drawTableHeader(renderer: ReportPDFRenderer) {
        let columns = tableColumns(in: renderer.contentRect)
        let y = renderer.y - 12
        let font = NSFont.boldSystemFont(ofSize: 8.5)
        renderer.drawText("Order #", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.orderNumber.minX, y: y, width: columns.orderNumber.width, height: 12))
        renderer.drawText("Student Name", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.student.minX, y: y, width: columns.student.width, height: 12))
        renderer.drawText("Class", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.className.minX, y: y, width: columns.className.width, height: 12))
        renderer.drawText("School", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.school.minX, y: y, width: columns.school.width, height: 12))
        renderer.drawText("Qty", font: font, color: .secondaryLabelColor, alignment: .center, rect: CGRect(x: columns.quantity.minX, y: y, width: columns.quantity.width, height: 12))
        renderer.drawText("Extras", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.extras.minX, y: y, width: columns.extras.width, height: 12))
        renderer.moveDown(14)
        renderer.drawDivider(y: renderer.y)
        renderer.moveDown(6)
    }

    private func draw(_ row: PastaRow, height: CGFloat, renderer: ReportPDFRenderer) {
        let columns = tableColumns(in: renderer.contentRect)
        let y = renderer.y - height + 1.5
        let textHeight = height - 2.5
        let font = NSFont.systemFont(ofSize: 7.5)
        let quantityFont = NSFont.boldSystemFont(ofSize: 8)
        let orderFont = NSFont.boldSystemFont(ofSize: 7.5)

        renderer.drawText(row.orderNumber, font: orderFont, rect: CGRect(x: columns.orderNumber.minX, y: y, width: columns.orderNumber.width, height: textHeight))
        renderer.drawText(row.studentName, font: font, rect: CGRect(x: columns.student.minX, y: y, width: columns.student.width, height: textHeight))
        renderer.drawText(row.className, font: font, rect: CGRect(x: columns.className.minX, y: y, width: columns.className.width, height: textHeight))
        renderer.drawText(row.schoolName, font: font, rect: CGRect(x: columns.school.minX, y: y, width: columns.school.width, height: textHeight))
        renderer.drawText("\(row.quantity)", font: quantityFont, alignment: .center, rect: CGRect(x: columns.quantity.minX, y: y, width: columns.quantity.width, height: textHeight))
        drawWrappedText(
            row.extras,
            font: font,
            rect: CGRect(x: columns.extras.minX, y: y, width: columns.extras.width, height: textHeight)
        )
        renderer.drawDivider(y: renderer.y - height, color: .separatorColor.withAlphaComponent(0.45))
        renderer.moveDown(height)
    }

    private func height(for row: PastaRow, renderer: ReportPDFRenderer) -> CGFloat {
        let columns = tableColumns(in: renderer.contentRect)
        let extrasHeight = measuredHeight(row.extras, font: .systemFont(ofSize: 7.5), width: columns.extras.width)
        return max(PastaRow.minimumHeight, ceil(extrasHeight) + 3.5)
    }

    private func tableColumns(in contentRect: CGRect) -> PastaTableColumns {
        let orderWidth: CGFloat = 48
        let studentWidth: CGFloat = 116
        let classWidth: CGFloat = 52
        let schoolWidth: CGFloat = 95
        let quantityWidth: CGFloat = 30
        let gap: CGFloat = 8
        let studentX = contentRect.minX + orderWidth + gap
        let classX = studentX + studentWidth + gap
        let schoolX = classX + classWidth + gap
        let quantityX = schoolX + schoolWidth + gap
        let extrasX = quantityX + quantityWidth + gap

        return PastaTableColumns(
            orderNumber: CGRect(x: contentRect.minX, y: 0, width: orderWidth, height: 0),
            student: CGRect(x: studentX, y: 0, width: studentWidth, height: 0),
            className: CGRect(x: classX, y: 0, width: classWidth, height: 0),
            school: CGRect(x: schoolX, y: 0, width: schoolWidth, height: 0),
            quantity: CGRect(x: quantityX, y: 0, width: quantityWidth, height: 0),
            extras: CGRect(x: extrasX, y: 0, width: contentRect.maxX - extrasX, height: 0)
        )
    }

    private func pastaItemName(for item: MenuItem) -> String {
        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unnamed Item" : trimmedName
    }

    private func printPastaDebugOutput(
        totalOrdersProcessed: Int,
        totalStudentOrdersProcessed: Int,
        totalMenuItemsProcessed: Int,
        matchedItemNames: [String]
    ) {
        print("PastaPreparationReportService debug")
        print("Total orders processed: \(totalOrdersProcessed)")
        print("Total student orders processed: \(totalStudentOrdersProcessed)")
        print("Total menu items processed: \(totalMenuItemsProcessed)")
        print("Total pasta items found: \(matchedItemNames.count)")
        print("Every item name that isPastaItem() matched:")
        if matchedItemNames.isEmpty {
            print("- none")
        } else {
            for itemName in matchedItemNames {
                print("- \(itemName)")
            }
        }
        print("Implementation of isPastaItem():")
        print("""
        private func isPastaItem(_ item: MenuItem) -> Bool {
            item.name.localizedCaseInsensitiveContains("pasta")
        }
        """)
        print("Implementation of pastaItemName(for:):")
        print("""
        private func pastaItemName(for item: MenuItem) -> String {
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedName.isEmpty ? "Unnamed Item" : trimmedName
        }
        """)
    }

    private func pastaExtras(for item: MenuItem) -> String {
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

    private func isPastaItem(_ item: MenuItem) -> Bool {
        print("Checking item name: '\(item.name)'")

        return item.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveContains("pasta")
    }

    private func hasParmesan(in extras: String) -> Bool {
        let normalizedExtras = extras.normalizedPastaPreparationText
        guard normalizedExtras.contains("parmesan") else { return false }
        return !normalizedExtras.contains("no parmesan")
            && !normalizedExtras.contains("without parmesan")
            && !normalizedExtras.contains("parmesan no")
            && !normalizedExtras.contains("parmesan none")
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

    private func measuredHeight(_ text: String, font: NSFont, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return PastaRow.minimumHeight - 7 }

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

private struct PastaStatistics {
    var totalOrders: Int
    var totalStudents: Int
}

private struct PastaSection {
    var itemName: String
    var totalQuantity: Int
    var parmesanYesQuantity: Int
    var parmesanNoQuantity: Int
    var rows: [PastaRow]
}

private struct PastaRow {
    static let minimumHeight: CGFloat = 12

    var studentOrderID: UUID
    var orderNumber: String
    var studentName: String
    var className: String
    var schoolName: String
    var quantity: Int
    var extras: String
    var hasParmesan: Bool
}

private struct PastaTableColumns {
    var orderNumber: CGRect
    var student: CGRect
    var className: CGRect
    var school: CGRect
    var quantity: CGRect
    var extras: CGRect
}

private extension String {
    var normalizedPastaPreparationText: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
