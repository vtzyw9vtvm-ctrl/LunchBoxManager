import AppKit
import Foundation
import PDFKit

/// Generates per-school class packing list PDFs with one A5 page per class.
struct ClassPackingListService {
    func makeReports(from orders: [LunchOrder], date: Date = Date()) -> [ClassPackingListReport] {
        Dictionary(grouping: orders, by: { displaySchoolName($0.school.name) })
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { schoolName, schoolOrders in
                ClassPackingListReport(
                    schoolName: schoolName,
                    document: makeDocument(schoolName: schoolName, orders: schoolOrders, date: date)
                )
            }
    }

    private func makeDocument(schoolName: String, orders: [LunchOrder], date: Date) -> PDFDocument {
        guard let renderer = ReportPDFRenderer(pageSize: ReportPDFRenderer.a5PortraitSize, margin: 24) else {
            return PDFDocument()
        }

        let pages = makeClassPages(from: orders)
        for page in pages {
            draw(page, schoolName: schoolName, date: date, renderer: renderer)
        }

        return renderer.finish()
    }

    private func makeClassPages(from orders: [LunchOrder]) -> [ClassPackingPage] {
        var ordersByClass: [String: [ClassStudentOrder]] = [:]
        var displayNameByClass: [String: String] = [:]

        for order in orders {
            for studentOrder in order.studentOrders {
                let className = displayClassName(studentOrder.schoolClass?.name ?? "")
                let classKey = className.normalizedClassKey
                displayNameByClass[classKey] = className
                ordersByClass[classKey, default: []].append(
                    ClassStudentOrder(
                        orderNumber: order.orderNumber,
                        studentName: displayStudentName(studentOrder.student.fullName),
                        className: className,
                        items: studentOrder.items.map { item in
                            ClassPackingItem(
                                name: displayItemName(item.name),
                                quantity: item.quantity,
                                extras: extras(for: item)
                            )
                        }
                    )
                )
            }
        }

        return ordersByClass.map { classKey, studentOrders in
            let sortedStudentOrders = studentOrders.sorted {
                $0.studentName.localizedStandardCompare($1.studentName) == .orderedAscending
            }
            return ClassPackingPage(
                className: displayNameByClass[classKey] ?? "Unassigned",
                studentOrders: sortedStudentOrders
            )
        }
        .sorted { sortClass($0.className, before: $1.className) }
    }

    private func draw(_ page: ClassPackingPage, schoolName: String, date: Date, renderer: ReportPDFRenderer) {
        renderer.beginPage()
        drawHeader(page, schoolName: schoolName, date: date, renderer: renderer)
        drawTableHeader(renderer: renderer)

        for studentOrder in page.studentOrders {
            draw(studentOrder, renderer: renderer)
        }

        renderer.endPage()
    }

    private func drawHeader(_ page: ClassPackingPage, schoolName: String, date: Date, renderer: ReportPDFRenderer) {
        let contentRect = renderer.contentRect
        renderer.setY(
            renderer.drawText(
                schoolName,
                font: .boldSystemFont(ofSize: 13),
                color: .secondaryLabelColor,
                rect: CGRect(x: contentRect.minX, y: renderer.y - 18, width: contentRect.width, height: 18)
            )
        )
        renderer.moveDown(2)
        renderer.setY(
            renderer.drawText(
                page.className,
                font: .boldSystemFont(ofSize: 26),
                rect: CGRect(x: contentRect.minX, y: renderer.y - 34, width: contentRect.width, height: 34)
            )
        )
        renderer.moveDown(2)
        renderer.setY(
            renderer.drawText(
                reportDateFormatter.string(from: date),
                font: .systemFont(ofSize: 10),
                color: .secondaryLabelColor,
                rect: CGRect(x: contentRect.minX, y: renderer.y - 14, width: contentRect.width, height: 14)
            )
        )
        renderer.moveDown(6)
        renderer.setY(
            renderer.drawText(
                "Total Orders: \(page.totalOrders)    Total Students: \(page.totalStudents)",
                font: .boldSystemFont(ofSize: 10),
                rect: CGRect(x: contentRect.minX, y: renderer.y - 14, width: contentRect.width, height: 14)
            )
        )
        renderer.moveDown(7)
        renderer.drawDivider(y: renderer.y)
        renderer.moveDown(8)
    }

    private func drawTableHeader(renderer: ReportPDFRenderer) {
        let columns = tableColumns(in: renderer.contentRect)
        let y = renderer.y - 11
        let font = NSFont.boldSystemFont(ofSize: 8)
        renderer.drawText("Order #", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.orderNumber.minX, y: y, width: columns.orderNumber.width, height: 11))
        renderer.drawText("Student", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.student.minX, y: y, width: columns.student.width, height: 11))
        renderer.drawText("Item", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.item.minX, y: y, width: columns.item.width, height: 11))
        renderer.drawText("Qty", font: font, color: .secondaryLabelColor, alignment: .center, rect: CGRect(x: columns.quantity.minX, y: y, width: columns.quantity.width, height: 11))
        renderer.drawText("Extras", font: font, color: .secondaryLabelColor, rect: CGRect(x: columns.extras.minX, y: y, width: columns.extras.width, height: 11))
        renderer.moveDown(13)
        renderer.drawDivider(y: renderer.y)
        renderer.moveDown(4)
    }

    private func draw(_ studentOrder: ClassStudentOrder, renderer: ReportPDFRenderer) {
        let requiredHeight = studentOrder.items.reduce(CGFloat(0)) { total, item in
            total + height(for: item, renderer: renderer)
        }
        guard renderer.y - requiredHeight >= renderer.contentRect.minY else { return }

        var isFirstItem = true
        for item in studentOrder.items {
            let rowHeight = height(for: item, renderer: renderer)
            draw(item, studentOrder: studentOrder, showStudentDetails: isFirstItem, height: rowHeight, renderer: renderer)
            isFirstItem = false
        }

        renderer.drawDivider(y: renderer.y - 1, color: .separatorColor.withAlphaComponent(0.65))
        renderer.moveDown(3)
    }

    private func draw(
        _ item: ClassPackingItem,
        studentOrder: ClassStudentOrder,
        showStudentDetails: Bool,
        height: CGFloat,
        renderer: ReportPDFRenderer
    ) {
        let columns = tableColumns(in: renderer.contentRect)
        let y = renderer.y - height + 1.5
        let textHeight = height - 2.5
        let font = NSFont.systemFont(ofSize: 7.5)
        let boldFont = NSFont.boldSystemFont(ofSize: 7.5)
        let quantityFont = NSFont.boldSystemFont(ofSize: 8)

        if showStudentDetails {
            renderer.drawText(studentOrder.orderNumber, font: boldFont, rect: CGRect(x: columns.orderNumber.minX, y: y, width: columns.orderNumber.width, height: textHeight))
            renderer.drawText(studentOrder.studentName, font: boldFont, rect: CGRect(x: columns.student.minX, y: y, width: columns.student.width, height: textHeight))
        }

        renderer.drawText(item.name, font: font, rect: CGRect(x: columns.item.minX, y: y, width: columns.item.width, height: textHeight))
        renderer.drawText("\(item.quantity)", font: quantityFont, alignment: .center, rect: CGRect(x: columns.quantity.minX, y: y, width: columns.quantity.width, height: textHeight))
        drawWrappedText(item.extras, font: font, rect: CGRect(x: columns.extras.minX, y: y, width: columns.extras.width, height: textHeight))
        renderer.moveDown(height)
    }

    private func height(for item: ClassPackingItem, renderer: ReportPDFRenderer) -> CGFloat {
        let columns = tableColumns(in: renderer.contentRect)
        let extrasHeight = measuredHeight(item.extras, font: .systemFont(ofSize: 7.5), width: columns.extras.width)
        return max(11, ceil(extrasHeight) + 3)
    }

    private func tableColumns(in contentRect: CGRect) -> ClassPackingColumns {
        let orderWidth: CGFloat = 42
        let studentWidth: CGFloat = 82
        let quantityWidth: CGFloat = 24
        let gap: CGFloat = 6
        let itemWidth: CGFloat = 100
        let studentX = contentRect.minX + orderWidth + gap
        let itemX = studentX + studentWidth + gap
        let quantityX = itemX + itemWidth + gap
        let extrasX = quantityX + quantityWidth + gap

        return ClassPackingColumns(
            orderNumber: CGRect(x: contentRect.minX, y: 0, width: orderWidth, height: 0),
            student: CGRect(x: studentX, y: 0, width: studentWidth, height: 0),
            item: CGRect(x: itemX, y: 0, width: itemWidth, height: 0),
            quantity: CGRect(x: quantityX, y: 0, width: quantityWidth, height: 0),
            extras: CGRect(x: extrasX, y: 0, width: contentRect.maxX - extrasX, height: 0)
        )
    }

    private func extras(for item: MenuItem) -> String {
        var details = item.variants.compactMap(cleanExtrasText)
        if let notes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty,
           let cleanedNotes = cleanExtrasText(notes) {
            details.append(cleanedNotes)
        }

        return details.joined(separator: "; ")
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
        guard !text.isEmpty else { return 8 }

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

    private func displayItemName(_ itemName: String) -> String {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Unnamed Item" : trimmedName
    }

    private func sortClass(_ first: String, before second: String) -> Bool {
        let firstKey = classSortKey(first)
        let secondKey = classSortKey(second)
        if firstKey.yearRank != secondKey.yearRank {
            return firstKey.yearRank < secondKey.yearRank
        }
        return firstKey.normalizedName.localizedStandardCompare(secondKey.normalizedName) == .orderedAscending
    }

    private func classSortKey(_ className: String) -> (yearRank: Int, normalizedName: String) {
        let normalizedName = className.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedName = normalizedName.lowercased()
        if lowercasedName.contains("prep") || lowercasedName.hasPrefix("p") {
            return (0, normalizedName)
        }
        if let range = lowercasedName.range(of: #"\d+"#, options: .regularExpression),
           let year = Int(lowercasedName[range]) {
            return (year, normalizedName)
        }
        return (999, normalizedName)
    }

    private let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMM yyyy"
        return formatter
    }()
}

private struct ClassPackingPage {
    var className: String
    var studentOrders: [ClassStudentOrder]

    var totalOrders: Int {
        Set(studentOrders.map(\.orderNumber)).count
    }

    var totalStudents: Int {
        studentOrders.count
    }
}

private struct ClassStudentOrder {
    var orderNumber: String
    var studentName: String
    var className: String
    var items: [ClassPackingItem]
}

private struct ClassPackingItem {
    var name: String
    var quantity: Int
    var extras: String
}

private struct ClassPackingColumns {
    var orderNumber: CGRect
    var student: CGRect
    var item: CGRect
    var quantity: CGRect
    var extras: CGRect
}

private extension String {
    var normalizedClassKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
