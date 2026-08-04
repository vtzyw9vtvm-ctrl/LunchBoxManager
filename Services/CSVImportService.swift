import Foundation

/// Result returned after importing a CSV order export.
struct CSVImportResult: Sendable {
    var session: ImportSession
    var orders: [LunchOrder]
    var issues: [CSVImportIssue]
    var summary: ImportSummary
}

/// Summary values shown after a completed import.
struct ImportSummary: Hashable, Sendable {
    var totalMenuItems: Int
    var capitalisationCorrections: Int
    var duplicateClasses: Int
    var skippedRows: Int
}

/// Imports the official Wix school lunch CSV export format.
struct CSVImportService: Sendable {
    func readHeaders(from fileURL: URL) async throws -> [String] {
        let text = try readText(from: fileURL)
        guard let headerLine = text.splitIntoLines().first else { return [] }
        return parseCSVLine(headerLine).map { $0.cleanedCSVValue }
    }

    func importOrders(from fileURL: URL) async throws -> CSVImportResult {
        let text = try readText(from: fileURL).removingByteOrderMark
        let lines = text.splitIntoLines()
        let dataLines = Array(lines.dropFirst())
        let parsedRows = dataLines.enumerated().map { index, rawLine in
            ParsedCSVRow(
                lineNumber: index + 2,
                rawLine: rawLine,
                columns: parseCSVLine(rawLine).map { $0.cleanedCSVValue }
            )
        }
        let nonEmptyRows = parsedRows.filter { !$0.columns.allSatisfy(\.isEmpty) }

        printParsedRows(nonEmptyRows)

        let result = makeImportResult(from: nonEmptyRows, filename: fileURL.lastPathComponent)
        printImportSummary(rowsRead: nonEmptyRows.count, orders: result.orders)
        return result
    }

    private func readText(from fileURL: URL) throws -> String {
        try String(contentsOf: fileURL, encoding: .utf8)
    }

    private func removeLineBreaksInsideQuotes(_ text: String) -> String {
        var result = ""
        var insideQuotes = false

        for character in text {
            if character == "\"" {
                insideQuotes.toggle()
                result.append(character)
            } else if insideQuotes && (character == "\n" || character == "\r") {
                if result.last != " " {
                    result.append(" ")
                }
            } else {
                result.append(character)
            }
        }

        return result
    }

    private func makeImportResult(from rows: [ParsedCSVRow], filename: String) -> CSVImportResult {
        var buildersByOrderAndSchool: [String: LunchOrderBuilder] = [:]
        var orderAndSchoolKeys: [String] = []
        var schoolsByName: [String: School] = [:]
        var classesByKey: [String: SchoolClass] = [:]
        var issues: [CSVImportIssue] = []
        var skippedRows = 0

        for row in rows {
            let columns = row.columns
            let orderNumber = value(at: 0, in: columns)
            let itemName = value(at: 1, in: columns)
            let variantText = value(at: 2, in: columns)
            let quantity = max(Int(value(at: 3, in: columns)) ?? 1, 1)
            let customText = value(at: 4, in: columns)
            let deliveryMethod = value(at: 5, in: columns)

            let rejectionReason = rowRejectionReason(
                orderNumber: orderNumber,
                itemName: itemName,
                deliveryMethod: deliveryMethod
            )
            guard rejectionReason == nil else {
                skippedRows += 1
                logInvalidRow(
                    row,
                    orderNumber: orderNumber,
                    itemName: itemName,
                    deliveryMethod: deliveryMethod,
                    reason: rejectionReason ?? "Unknown rejection reason"
                )
                continue
            }

            let studentName = extractStudentName(from: customText)
            let className = extractClassName(from: variantText)
            let itemVariants = extractItemVariants(from: variantText)
            let customInstructions = extractCustomInstructions(from: customText)
            let school = makeSchool(named: deliveryMethod, cache: &schoolsByName)
            let schoolClass = makeSchoolClass(named: className, school: school, cache: &classesByKey)
            let item = MenuItem(
                name: itemName,
                category: "Lunch",
                variants: itemVariants,
                quantity: quantity,
                notes: customInstructions
            )
            let orderKey = orderNumber.isEmpty ? "row-\(row.lineNumber)" : orderNumber
            let orderAndSchoolKey = orderSchoolKey(orderKey: orderKey, schoolName: school.name)
            let studentOrderKey = classOrderKey(className: className, rowLineNumber: row.lineNumber)

            if buildersByOrderAndSchool[orderAndSchoolKey] == nil {
                buildersByOrderAndSchool[orderAndSchoolKey] = LunchOrderBuilder(
                    orderNumber: orderNumber,
                    school: school,
                    orderDate: Date()
                )
                orderAndSchoolKeys.append(orderAndSchoolKey)
            }

            buildersByOrderAndSchool[orderAndSchoolKey]?.append(
                item,
                studentName: studentName,
                schoolClass: schoolClass,
                studentOrderKey: studentOrderKey,
                lineNumber: row.lineNumber,
                issues: &issues
            )
        }

        let builders = orderAndSchoolKeys.compactMap { buildersByOrderAndSchool[$0] }
        let orders = builders.map { $0.makeLunchOrder() }
        let summary = ImportSummary(
            totalMenuItems: orders.totalMenuItems,
            capitalisationCorrections: builders.reduce(0) { $0 + $1.capitalisationCorrections },
            duplicateClasses: 0,
            skippedRows: skippedRows
        )
        let session = ImportSession(
            filename: filename,
            importDate: Date(),
            totalOrders: orders.count,
            totalStudents: orders.studentOrderCount,
            totalClasses: Set(orders.flatMap { $0.studentOrders.compactMap(\.schoolClass?.id) }).count,
            totalSchools: Set(orders.filter { !$0.school.name.isEmpty }.map(\.school.id)).count
        )

        return CSVImportResult(session: session, orders: orders, issues: issues, summary: summary)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var isInsideQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let character = line[index]

            if character == "\"" {
                let nextIndex = line.index(after: index)
                if isInsideQuotes, nextIndex < line.endIndex, line[nextIndex] == "\"" {
                    field.append(character)
                    index = nextIndex
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == ",", !isInsideQuotes {
                fields.append(field)
                field = ""
            } else {
                field.append(character)
            }

            index = line.index(after: index)
        }

        fields.append(field)
        return fields
    }

    private func extractStudentName(from customText: String) -> String {
        guard let range = customText.range(
            of: #"Child's Name:\s*([^\r\n|;]+)"#,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            return ""
        }

        let match = String(customText[range])
        guard let separatorIndex = match.firstIndex(of: ":") else { return "" }
        return String(match[match.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractCustomInstructions(from customText: String) -> String? {
        let instructions = customText
            .replacingOccurrences(
                of: #"Child's Name:\s*([^\r\n|;]+)"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .components(separatedBy: CharacterSet(charactersIn: "\r\n|;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "; ")

        return instructions.isEmpty ? nil : instructions
    }

    private func extractClassName(from variant: String) -> String {
        guard let range = variant.range(
            of: #"CLASS:\s*([^|]+)"#,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            return ""
        }

        let match = String(variant[range])
        guard let separatorIndex = match.firstIndex(of: ":") else { return "" }
        return String(match[match.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractItemVariants(from variant: String) -> [String] {
        variant
            .components(separatedBy: "|")
            .compactMap(cleanVariantComponent)
    }

    private func cleanVariantComponent(_ component: String) -> String? {
        let trimmedComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComponent.isEmpty else { return nil }

        guard let separatorIndex = trimmedComponent.firstIndex(of: ":") else {
            return shouldDisplayVariantValue(trimmedComponent) ? trimmedComponent : nil
        }

        let fieldName = String(trimmedComponent[..<separatorIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let value = String(trimmedComponent[trimmedComponent.index(after: separatorIndex)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard fieldName.caseInsensitiveCompare("CLASS") != .orderedSame else { return nil }
        guard shouldDisplayVariantValue(value) else { return nil }

        if value.caseInsensitiveCompare("Yes") == .orderedSame {
            return fieldName
        }

        return value
    }

    private func shouldDisplayVariantValue(_ value: String) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return false }

        let hiddenValues = ["No", "None", "N/A"]
        return !hiddenValues.contains { $0.caseInsensitiveCompare(trimmedValue) == .orderedSame }
    }

    private func value(at index: Int, in row: [String]) -> String {
        index < row.count ? row[index] : ""
    }

    private func rowRejectionReason(orderNumber: String, itemName: String, deliveryMethod: String) -> String? {
        var missingFields: [String] = []
        if orderNumber.isEmpty {
            missingFields.append("Order Number")
        }
        if itemName.isEmpty {
            missingFields.append("Item")
        }
        if deliveryMethod.isEmpty {
            missingFields.append("Delivery Method")
        }

        return missingFields.isEmpty ? nil : "Missing required field(s): \(missingFields.joined(separator: ", "))"
    }

    private func logInvalidRow(
        _ row: ParsedCSVRow,
        orderNumber: String,
        itemName: String,
        deliveryMethod: String,
        reason: String
    ) {
        print("Skipping invalid CSV record \(row.lineNumber)")
        print("Reason = \(reason)")
        print("Order Number = \(orderNumber.isEmpty ? "<missing>" : orderNumber)")
        print("Item = \(itemName.isEmpty ? "<missing>" : itemName)")
        print("Delivery Method = \(deliveryMethod.isEmpty ? "<missing>" : deliveryMethod)")
        print("Columns = \(row.columns.count)")
        for (index, column) in row.columns.enumerated() {
            print("[\(index)] = \(column)")
        }
        print("Raw record = \(row.rawLine)")
    }

    private func makeSchool(named schoolName: String, cache: inout [String: School]) -> School {
        if let school = cache[schoolName] {
            return school
        }

        let school = School(name: schoolName, shortName: shortName(for: schoolName))
        cache[schoolName] = school
        return school
    }

    private func makeSchoolClass(
        named className: String,
        school: School,
        cache: inout [String: SchoolClass]
    ) -> SchoolClass? {
        guard !className.isEmpty else { return nil }

        let key = "\(school.id.uuidString)|\(className)"
        if let schoolClass = cache[key] {
            return schoolClass
        }

        let schoolClass = SchoolClass(name: className, yearLevel: className, schoolID: school.id)
        cache[key] = schoolClass
        return schoolClass
    }

    private func orderSchoolKey(orderKey: String, schoolName: String) -> String {
        let normalizedSchoolName = schoolName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(orderKey)|\(normalizedSchoolName)"
    }

    private func classOrderKey(className: String, rowLineNumber _: Int) -> String {
        className.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func shortName(for schoolName: String) -> String {
        let initials = schoolName
            .split(separator: " ")
            .compactMap(\.first)
            .map(String.init)
            .joined()
        return initials.isEmpty ? schoolName : initials.uppercased()
    }

    private func printParsedRows(_ rows: [ParsedCSVRow]) {
        for (index, row) in rows.prefix(20).enumerated() {
            print("Row \(index + 1):")
            print("Columns = \(row.columns.count)")

            for columnIndex in 0..<6 {
                let value = columnIndex < row.columns.count ? row.columns[columnIndex] : ""
                print("[\(columnIndex)] = \(value)")
            }

            if row.columns.count != 6 {
                print("Raw line = \(row.rawLine)")
            }
        }
    }

    private func printImportSummary(rowsRead: Int, orders: [LunchOrder]) {
        print("Rows read: \(rowsRead)")
        print("Orders: \(orders.count)")
        print("Students: \(orders.studentOrderCount)")
        print("Classes: \(Set(orders.flatMap { $0.studentOrders.compactMap(\.schoolClass?.id) }).count)")
        print("Schools: \(Set(orders.filter { !$0.school.name.isEmpty }.map(\.school.id)).count)")

        if let firstOrder = orders.first {
            print("First parsed LunchOrder:")
            print(firstOrder)
        }
    }
}

private struct ParsedCSVRow {
    var lineNumber: Int
    var rawLine: String
    var columns: [String]
}

private struct LunchOrderBuilder {
    var orderNumber: String
    var school: School
    var orderDate: Date
    private var studentOrdersByKey: [String: StudentOrderBuilder] = [:]
    private var studentOrderKeys: [String] = []

    init(orderNumber: String, school: School, orderDate: Date) {
        self.orderNumber = orderNumber
        self.school = school
        self.orderDate = orderDate
    }

    var capitalisationCorrections: Int {
        studentOrdersByKey.values.reduce(0) { $0 + $1.capitalisationCorrections }
    }

    mutating func append(
        _ item: MenuItem,
        studentName: String,
        schoolClass: SchoolClass?,
        studentOrderKey: String,
        lineNumber: Int,
        issues: inout [CSVImportIssue]
    ) {
        if var existingStudentOrder = studentOrdersByKey[studentOrderKey] {
            existingStudentOrder.append(item, studentName: studentName, lineNumber: lineNumber, issues: &issues)
            studentOrdersByKey[studentOrderKey] = existingStudentOrder
        } else {
            studentOrdersByKey[studentOrderKey] = StudentOrderBuilder(
                studentName: studentName,
                schoolClass: schoolClass,
                items: [item]
            )
            studentOrderKeys.append(studentOrderKey)
        }
    }

    func makeLunchOrder() -> LunchOrder {
        LunchOrder(
            orderNumber: orderNumber,
            school: school,
            studentOrders: studentOrderKeys.compactMap { studentOrdersByKey[$0]?.makeStudentOrder() },
            orderDate: orderDate
        )
    }
}

private struct StudentOrderBuilder {
    var studentName: String
    var schoolClass: SchoolClass?
    var items: [MenuItem]
    var capitalisationCorrections: Int

    init(studentName: String, schoolClass: SchoolClass?, items: [MenuItem]) {
        let trimmedName = studentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmedName.titleCasedName
        self.studentName = displayName
        self.schoolClass = schoolClass
        self.items = items
        self.capitalisationCorrections = trimmedName.needsTitleCaseCorrection(displayName: displayName) ? 1 : 0
    }

    mutating func append(
        _ item: MenuItem,
        studentName newStudentName: String,
        lineNumber: Int,
        issues: inout [CSVImportIssue]
    ) {
        let existingName = studentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newName = newStudentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = newName.titleCasedName

        if existingName.isEmpty, !newName.isEmpty {
            studentName = displayName
            if newName.needsTitleCaseCorrection(displayName: displayName) {
                capitalisationCorrections += 1
            }
        } else if !newName.isEmpty,
                  !existingName.isEmpty,
                  existingName.caseInsensitiveCompare(newName) != .orderedSame {
            let message = "Different student name '\(newName)' found for the same order number and class. Keeping '\(existingName)'."
            print("Import warning line \(lineNumber): \(message)")
            issues.append(CSVImportIssue(lineNumber: lineNumber, message: message))
        }

        items.append(item)
    }

    func makeStudentOrder() -> StudentOrder {
        let student = makeStudent(named: studentName, classID: schoolClass?.id)
        return StudentOrder(student: student, schoolClass: schoolClass, items: items)
    }

    private func makeStudent(named studentName: String, classID: UUID?) -> Student {
        let nameParts = studentName.split(separator: " ", maxSplits: 1).map(String.init)
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.count > 1 ? nameParts[1] : ""
        return Student(firstName: firstName, lastName: lastName, fullName: studentName, classID: classID)
    }
}

private extension Array where Element == LunchOrder {
    var studentOrderCount: Int {
        reduce(0) { $0 + $1.studentOrders.count }
    }

    var totalMenuItems: Int {
        reduce(0) { total, order in
            total + order.studentOrders.reduce(0) { studentTotal, studentOrder in
                studentTotal + studentOrder.items.reduce(0) { $0 + $1.quantity }
            }
        }
    }
}

private extension String {
    var removingByteOrderMark: String {
        replacingOccurrences(of: "\u{FEFF}", with: "")
    }

    var cleanedCSVValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines).removingSurroundingQuotationMarks
    }

    var removingSurroundingQuotationMarks: String {
        guard count >= 2, first == "\"", last == "\"" else { return self }
        return String(dropFirst().dropLast())
    }

    var titleCasedName: String {
        split(separator: " ")
            .map { word in
                let lowercasedWord = word.lowercased()
                guard let firstCharacter = lowercasedWord.first else { return "" }
                return String(firstCharacter).uppercased() + lowercasedWord.dropFirst()
            }
            .joined(separator: " ")
    }

    func needsTitleCaseCorrection(displayName: String) -> Bool {
        !isEmpty && self != displayName
    }

    func splitIntoLines() -> [String] {
        components(separatedBy: "\r\n")
            .flatMap { $0.components(separatedBy: "\n") }
    }
}
