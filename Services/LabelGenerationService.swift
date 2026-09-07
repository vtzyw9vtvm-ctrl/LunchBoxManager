import AppKit
import Foundation
import PDFKit

/// Builds hot lunch labels and renders them as thermal-label PDF pages.
struct LabelGenerationService {
    static let labelSize = CGSize(width: 80.0 / 25.4 * 72.0, height: 60.0 / 25.4 * 72.0)

    private let coldItemConfiguration: ColdLabelItemConfiguration

    init(coldItemConfiguration: ColdLabelItemConfiguration? = nil) {
        self.coldItemConfiguration = coldItemConfiguration ?? .load()
    }

    func makeHotLabels(from orders: [LunchOrder]) -> [LunchLabel] {
        makeLabels(from: orders, mode: .hot)
    }

    func makeColdLabels(from orders: [LunchOrder]) -> [LunchLabel] {
        makeLabels(from: orders, mode: .cold)
    }

    private func makeLabels(from orders: [LunchOrder], mode: LabelTemperature) -> [LunchLabel] {
        var labels: [LunchLabel] = []

        for order in orders {
            for studentOrder in order.studentOrders {
                let matchingItems = studentOrder.items.filter { item in
                    item.activeQuantity > 0 &&
                    mode.includes(item, service: self)
                }
                guard !matchingItems.isEmpty else { continue }

                labels.append(
                    LunchLabel(
                        orderNumber: order.orderNumber,
                        schoolName: order.school.name,
                        className: displayClassName(studentOrder.schoolClass?.name ?? ""),
                        studentName: studentOrder.student.fullName,
                        foodAllergies: studentOrder.student.allergies,
                        items: matchingItems
                    )
                )
            }
        }

        return labels.sorted(by: shouldSortBefore)
    }

    func makePDFDocument(for labels: [LunchLabel]) -> PDFDocument {

        let data = NSMutableData()

        guard let consumer = CGDataConsumer(data: data) else {
            return PDFDocument()
        }

        var mediaBox = CGRect(
            origin: .zero,
            size: Self.labelSize
        )

        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &mediaBox,
            nil
        ) else {
            return PDFDocument()
        }

        for label in labels {

            let pages = paginatedItems(for: label)

            for (pageIndex, items) in pages.enumerated() {

                context.beginPDFPage(nil)

                NSGraphicsContext.saveGraphicsState()

                NSGraphicsContext.current =
                    NSGraphicsContext(
                        cgContext: context,
                        flipped: false
                    )

                draw(
                    label,
                    items: items,
                    pageNumber: pageIndex + 1,
                    totalPages: pages.count,
                    in: mediaBox
                )

                NSGraphicsContext.restoreGraphicsState()

                context.endPDFPage()
            }
        }

        context.closePDF()

        return PDFDocument(data: data as Data)
            ?? PDFDocument()
    }
    
    // MARK: - Label Pagination

    private func paginatedItems(
        for label: LunchLabel
    ) -> [[MenuItem]] {

        let availableItemHeight: CGFloat = 105

        var pages: [[MenuItem]] = []
        var currentPage: [MenuItem] = []
        var currentHeight: CGFloat = 0

        for item in label.items {

            let itemHeight =
                estimatedHeight(for: item)

            if !currentPage.isEmpty &&
                currentHeight + itemHeight > availableItemHeight {

                pages.append(currentPage)

                currentPage = []
                currentHeight = 0
            }

            currentPage.append(item)
            currentHeight += itemHeight
        }

        if !currentPage.isEmpty {
            pages.append(currentPage)
        }

        return pages.isEmpty ? [[]] : pages
    }

    private func estimatedHeight(
        for item: MenuItem
    ) -> CGFloat {

        let itemFont =
            NSFont.boldSystemFont(ofSize: 11)

        let modifierFont =
            italicSystemFont(ofSize: 9)

        let noteFont =
            NSFont.boldSystemFont(ofSize: 8)

        var height = ceil(
            itemFont.ascender -
            itemFont.descender +
            itemFont.leading +
            2
        )

        let details = item.displayVariants

        if !details.isEmpty ||
            cleanedSpecialInstructions(for: item) != nil {

            height += 0.5
        }

        for _ in details {
            height += ceil(
                modifierFont.ascender -
                modifierFont.descender +
                modifierFont.leading +
                0.5
            )
        }

        if cleanedSpecialInstructions(for: item) != nil {
            height += ceil(
                noteFont.ascender -
                noteFont.descender +
                noteFont.leading +
                0.5
            )
        }

        height += 2.25

        return height
    }

    private func cleanedSpecialInstructions(
        for item: MenuItem
    ) -> String? {

        guard
            let notes = item.notes?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !notes.isEmpty,
            let cleanedNotes =
                notes.cleanedLabelVariant
        else {
            return nil
        }

        return cleanedNotes
    }

    fileprivate func isHotItem(_ item: MenuItem) -> Bool {
        !isColdItem(item)
    }

    fileprivate func isColdItem(_ item: MenuItem) -> Bool {
        if item.isCold {
            return true
        }

        let itemName = item.name.normalizedItemName
        return coldItemConfiguration.normalizedItemNames.contains {
            itemName.contains($0)
        }
    }

    fileprivate func isDrinkItem(_ item: MenuItem) -> Bool {
        let itemName = item.name.normalizedItemName
        return drinkItemNames.contains { itemName.contains($0.normalizedItemName) }
    }

    private var drinkItemNames: [String] {
        [
            "Boost Juice",
            "Iced Tea - 600ml",
            "Nippy's Milk - 375ml",
            "Presha Fruit Juice",
            "Just Juice Box - 200ml",
            "Bottled Water - 600ml"
        ]
    }

    private func shouldSortBefore(_ first: LunchLabel, _ second: LunchLabel) -> Bool {
        compare(first.orderNumber, second.orderNumber)
            ?? compare(first.className, second.className)
            ?? false
    }

    private func compare(_ first: String, _ second: String) -> Bool? {
        let result = first.localizedStandardCompare(second)
        switch result {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return nil
        }
    }
    private func formattedOrderNumber(_ orderNumber: String) -> String {
        guard let number = Int(orderNumber) else {
            return orderNumber
        }

        return String(format: "%05d", number)
    }
    private func displayClassName(_ className: String) -> String {
        let trimmedClass = className.trimmingCharacters(in: .whitespacesAndNewlines)
        let classWithoutYear = trimmedClass.replacingOccurrences(
            of: #"^year\s+"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return classWithoutYear.titleCasedWords
    }

    private func draw(
        _ label: LunchLabel,
        items: [MenuItem],
        pageNumber: Int,
        totalPages: Int,
        in pageRect: CGRect
    ) {
        NSColor.white.setFill()
        pageRect.fill()

        let margin: CGFloat = 8
        let contentWidth = pageRect.width - margin * 2
        var y: CGFloat = pageRect.height - margin

        let headerTop = y
        if pageNumber == 1 {

            // MARK: - Full Header

            let classFont = NSFont.boldSystemFont(ofSize: 21)
            let studentFont = NSFont.boldSystemFont(ofSize: 11)

            let classText =
                label.className.isEmpty
                    ? "CLASS NOT SET"
                    : label.className

            let studentText =
                label.studentName.isEmpty
                    ? "Unnamed Student"
                    : label.studentName

            let headerGap: CGFloat = 8
            let minimumStudentWidth: CGFloat = 80

            let measuredClassWidth =
                measuredWidth(
                    of: classText,
                    font: classFont
                ) + 6

            let availableClassWidth = max(
                0,
                contentWidth -
                minimumStudentWidth -
                headerGap
            )

            let classWidth = min(
                measuredClassWidth,
                availableClassWidth
            )

            let studentWidth =
                contentWidth -
                classWidth -
                headerGap

            drawText(
                classText,
                font: classFont,
                rect: CGRect(
                    x: margin,
                    y: headerTop - 25,
                    width: classWidth,
                    height: 25
                )
            )

            drawText(
                studentText,
                font: studentFont,
                alignment: .right,
                rect: CGRect(
                    x: margin + classWidth + headerGap,
                    y: headerTop - 21,
                    width: studentWidth,
                    height: 21
                )
            )

            let allergies =
                label.foodAllergies
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            if !allergies.isEmpty {
                drawText(
                    "⚠ ALLERGY: \(allergies.uppercased())",
                    font: .boldSystemFont(ofSize: 9),
                    alignment: .right,
                    rect: CGRect(
                        x: margin + classWidth + headerGap,
                        y: headerTop - 33,
                        width: studentWidth,
                        height: 11
                    )
                )
            }

            y = drawText(
                "Order \(formattedOrderNumber(label.orderNumber))",
                font: .systemFont(ofSize: 8),
                color: .secondaryLabelColor,
                rect: CGRect(
                    x: margin,
                    y: headerTop - 35,
                    width: contentWidth,
                    height: 10
                )
            ) - 3

            drawDivider(
                in: CGRect(
                    x: margin,
                    y: y,
                    width: contentWidth,
                    height: 1
                )
            )

            y -= 4

        } else {

            // MARK: - Continuation Header

            let studentText =
                label.studentName.isEmpty
                    ? "Unnamed Student"
                    : label.studentName

            y = drawText(
                "CONTINUED — \(studentText.uppercased())",
                font: .boldSystemFont(ofSize: 10),
                rect: CGRect(
                    x: margin,
                    y: headerTop - 16,
                    width: contentWidth,
                    height: 14
                )
            ) - 3

            drawDivider(
                in: CGRect(
                    x: margin,
                    y: y,
                    width: contentWidth,
                    height: 1
                )
            )

            y -= 4
        }

       

        for item in items {

            y = drawLabelLine(
                "- \(item.activeQuantity) x \(item.name)",
                font: .boldSystemFont(ofSize: 11),
                x: margin,
                y: y,
                width: contentWidth,
                verticalPadding: 2
            )

            let details = item.displayVariants

            let specialInstructions =
                cleanedSpecialInstructions(for: item)

            if !details.isEmpty || specialInstructions != nil {
                y -= 0.5
            }

            // Normal selected modifiers / extras
            for detail in details {
                y = drawLabelLine(
                    detail,
                    font: italicSystemFont(ofSize: 9),
                    color: .secondaryLabelColor,
                    x: margin + 12,
                    y: y,
                    width: contentWidth - 12,
                    verticalPadding: 0.5
                )
            }

            // Parent-entered Special Instructions
            if let specialInstructions {
                y = drawLabelLine(
                    "NOTE: \(specialInstructions)",
                    font: .boldSystemFont(ofSize: 8),
                    color: .labelColor,
                    x: margin + 12,
                    y: y,
                    width: contentWidth - 12,
                    verticalPadding: 0.5
                )
            }

            y -= 2.25
        }
            if totalPages > 1 {
                drawText(
                    "\(pageNumber) of \(totalPages)",
                    font: .boldSystemFont(ofSize: 7),
                    color: .secondaryLabelColor,
                    alignment: .right,
                    rect: CGRect(
                        x: margin,
                        y: 4,
                        width: contentWidth,
                        height: 9
                    )
                )
            }
    }

    private func italicSystemFont(ofSize size: CGFloat) -> NSFont {
        let font = NSFont.systemFont(ofSize: size)
        return NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
    }

    private func measuredWidth(of text: String, font: NSFont) -> CGFloat {
        NSString(string: text).size(withAttributes: [.font: font]).width
    }

    @discardableResult
    private func drawLabelLine(
        _ text: String,
        font: NSFont,
        color: NSColor = .labelColor,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        verticalPadding: CGFloat
    ) -> CGFloat {
        let lineHeight = ceil(font.ascender - font.descender + font.leading + verticalPadding)
        return drawText(
            text,
            font: font,
            color: color,
            rect: CGRect(x: x, y: y - lineHeight, width: width, height: lineHeight)
        )
    }

    private func drawDivider(in rect: CGRect) {
        NSColor.separatorColor.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 0.5
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.stroke()
    }

    @discardableResult
    private func drawCentered(
        _ text: String,
        font: NSFont,
        color: NSColor = .labelColor,
        rect: CGRect
    ) -> CGFloat {
        drawText(text, font: font, color: color, alignment: .center, rect: rect)
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

struct ColdLabelItemConfiguration: Decodable {
    var coldItemNames: [String]

    var normalizedItemNames: [String] {
        coldItemNames.map(\.normalizedItemName)
    }

    static func load(bundle: Bundle = .main) -> ColdLabelItemConfiguration {
        guard let url = bundle.url(forResource: "ColdLabelItems", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let configuration = try? JSONDecoder().decode(ColdLabelItemConfiguration.self, from: data) else {
            return ColdLabelItemConfiguration(coldItemNames: fallbackColdItemNames)
        }

        return configuration
    }

    private static let fallbackColdItemNames = [
        "Monster Cookie",
        "Smartie Cookie",
        "Choc Chip Cookie",
        "Double Choc Muffin",
        "Banana Bread",
        "Fruit Cup",
        "Fruit Sticks",
        "Nutri-Grain Cereal Bar",
        "Kellogg's Berry & Nut Bar",
        "Choc Oat Bar",
        "Apricot Yoghurt Bar",
        "Chocolate Mousse",
        "Cheese Stick",
        "Gingerbread Man"
    ]
}

private enum LabelTemperature {
    case hot
    case cold

    func includes(_ item: MenuItem, service: LabelGenerationService) -> Bool {
        switch self {
        case .hot:
            true
        case .cold:
            service.isColdItem(item) && !service.isDrinkItem(item)
        }
    }
}

private extension MenuItem {
    var displayVariants: [String] {
        variants.compactMap { $0.cleanedLabelVariant }
    }
}

private extension String {
    var normalizedItemName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    var cleanedLabelVariant: String? {
        let trimmedValue = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        let fieldName: String
        let value: String

        if let separatorIndex = trimmedValue.firstIndex(of: ":") {
            fieldName = String(trimmedValue[..<separatorIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            value = String(trimmedValue[trimmedValue.index(after: separatorIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            fieldName = trimmedValue
            value = trimmedValue
        }

        // Nothing entered after "Special Instructions:"
        if value.isEmpty {
            return nil
        }

        guard shouldDisplayVariantValue(value) else {
            return nil
        }

        if value.caseInsensitiveCompare("Yes") == .orderedSame {
            return fieldName
        }

        return value
    }

    private func shouldDisplayVariantValue(_ value: String) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return false }

        let hiddenValues = [
            "No",
            "None",
            "N/A",
            "Special Instructions"
        ]

        return !hiddenValues.contains {
            $0.caseInsensitiveCompare(trimmedValue) == .orderedSame
        }
    }

    var titleCasedWords: String {
        split(separator: " ")
            .map { word in
                let wordText = String(word)
                if wordText.contains(where: { $0.isNumber }) {
                    return wordText.uppercased()
                }

                let lowercasedWord = wordText.lowercased()
                guard let firstCharacter = lowercasedWord.first else { return "" }
                return String(firstCharacter).uppercased() + lowercasedWord.dropFirst()
            }
            .joined(separator: " ")
    }
}
