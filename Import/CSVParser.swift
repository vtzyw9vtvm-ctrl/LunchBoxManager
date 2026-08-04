import Foundation

/// A parsed CSV document containing headers, data rows, and non-fatal parse issues.
struct CSVDocument: Sendable {
    var headers: [String]
    var rows: [CSVRow]
    var issues: [CSVImportIssue]
}

/// A parsed CSV row with its original line number.
struct CSVRow: Sendable {
    var lineNumber: Int
    var values: [String]
}

/// A non-fatal issue found while parsing or importing CSV content.
struct CSVImportIssue: Identifiable, Hashable, Sendable {
    let id: UUID
    var lineNumber: Int
    var message: String

    init(id: UUID = UUID(), lineNumber: Int, message: String) {
        self.id = id
        self.lineNumber = lineNumber
        self.message = message
    }
}

/// Parses UTF-8 CSV text into headers and rows.
struct CSVParser: Sendable {
    func splitHeaderLine(_ line: String) -> [String] {
        parseLine(line).map { $0.cleanedCSVHeader }
    }

    func parse(_ text: String) throws -> CSVDocument {
        let result = parseRows(from: text)
        guard let headerRow = result.rows.first(where: { !$0.values.allSatisfy { $0.cleanedCSVField.isEmpty } }) else {
            throw CSVParserError.missingHeader
        }

        let headers = headerRow.values.map { $0.cleanedCSVHeader }
        guard headers.contains(where: { !$0.isEmpty }) else {
            throw CSVParserError.missingHeader
        }

        var issues = result.issues
        var rows: [CSVRow] = []

        for row in result.rows where row.lineNumber > headerRow.lineNumber {
            let cleanedValues = row.values.map { $0.cleanedCSVField }
            if cleanedValues.allSatisfy(\.isEmpty) {
                continue
            }

            if cleanedValues.count != headers.count {
                issues.append(
                    CSVImportIssue(
                        lineNumber: row.lineNumber,
                        message: "Expected \(headers.count) columns but found \(cleanedValues.count)."
                    )
                )
            }

            rows.append(CSVRow(lineNumber: row.lineNumber, values: cleanedValues))
        }

        return CSVDocument(headers: headers, rows: rows, issues: issues)
    }

    private func parseLine(_ line: String) -> [String] {
        var values: [String] = []
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
                values.append(field)
                field = ""
            } else {
                field.append(character)
            }

            index = line.index(after: index)
        }

        values.append(field)
        return values
    }

    private func parseRows(from text: String) -> ParsedRows {
        var rows: [CSVRow] = []
        var issues: [CSVImportIssue] = []
        var values: [String] = []
        var field = ""
        var isInsideQuotes = false
        var quoteStartLine = 1
        var lineNumber = 1
        var rowStartLine = 1
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if character == "\"" {
                let nextIndex = text.index(after: index)
                if isInsideQuotes, nextIndex < text.endIndex, text[nextIndex] == "\"" {
                    field.append(character)
                    index = nextIndex
                } else {
                    if !isInsideQuotes {
                        quoteStartLine = lineNumber
                    }
                    isInsideQuotes.toggle()
                }
            } else if character == ",", !isInsideQuotes {
                values.append(field)
                field = ""
            } else if character == "\n", !isInsideQuotes {
                appendRow(values: &values, field: &field, lineNumber: rowStartLine, rows: &rows)
                lineNumber += 1
                rowStartLine = lineNumber
            } else if character == "\r", !isInsideQuotes {
                appendRow(values: &values, field: &field, lineNumber: rowStartLine, rows: &rows)

                let nextIndex = text.index(after: index)
                if nextIndex < text.endIndex, text[nextIndex] == "\n" {
                    index = nextIndex
                }

                lineNumber += 1
                rowStartLine = lineNumber
            } else {
                field.append(character)
                if character == "\n" || character == "\r" {
                    lineNumber += 1
                }
            }

            index = text.index(after: index)
        }

        if isInsideQuotes {
            issues.append(CSVImportIssue(lineNumber: quoteStartLine, message: "Unclosed quoted field."))
        }

        if !field.isEmpty || !values.isEmpty {
            appendRow(values: &values, field: &field, lineNumber: rowStartLine, rows: &rows)
        }

        return ParsedRows(rows: rows, issues: issues)
    }

    private func appendRow(values: inout [String], field: inout String, lineNumber: Int, rows: inout [CSVRow]) {
        values.append(field)
        rows.append(CSVRow(lineNumber: lineNumber, values: values))
        values = []
        field = ""
    }
}

/// Errors that prevent a CSV document from being parsed.
enum CSVParserError: LocalizedError {
    case missingHeader

    var errorDescription: String? {
        switch self {
        case .missingHeader:
            "The CSV file does not contain a header row."
        }
    }
}

private struct ParsedRows: Sendable {
    var rows: [CSVRow]
    var issues: [CSVImportIssue]
}

private extension String {
    var cleanedCSVHeader: String {
        removingByteOrderMark.cleanedCSVField
    }

    var cleanedCSVField: String {
        trimmingCharacters(in: .whitespacesAndNewlines).removingSurroundingQuotationMarks
    }

    var removingByteOrderMark: String {
        replacingOccurrences(of: "\u{FEFF}", with: "")
    }

    var removingSurroundingQuotationMarks: String {
        guard count >= 2, first == "\"", last == "\"" else { return self }
        return String(dropFirst().dropLast())
    }
}
