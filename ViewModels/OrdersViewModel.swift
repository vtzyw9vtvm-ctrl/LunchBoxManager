import Foundation
import Observation

/// Provides filtering, sorting, selection, and summary data for imported lunch orders.
enum OrdersDateView: String, CaseIterable, Identifiable, Sendable {

    case today = "Today"
    case upcoming = "Upcoming"
    case history = "History"

    var id: String { rawValue }
}
@MainActor
@Observable
final class OrdersViewModel {
    private(set) var orders: [LunchOrder]
    var allOrders: [LunchOrder] {
        orders
    }
    var searchText = ""
    var dateView: OrdersDateView = .today
    var selectedSchool = OrdersFilterOption.all
    var selectedClass = OrdersFilterOption.all
    var sortOption = OrdersSortOption.orderNumber
    var selectedRowID: OrderBrowserRow.ID?
    var selectedPrintRowIDs: Set<OrderBrowserRow.ID> = []

    init(orders: [LunchOrder]) {
        self.orders = orders
        self.selectedRowID = flattenedRows.first?.id
    }

    var filteredRows: [OrderBrowserRow] {
        flattenedRows
            .filter {
                matchesDate($0) &&
                matchesSearch($0) &&
                matchesSchool($0) &&
                matchesClass($0)
            }
            .sorted(using: sortOption)
    }
    
    var filteredOrdersForPrinting: [LunchOrder] {

        let rowsByOrder = Dictionary(
            grouping: filteredRows,
            by: \.orderID
        )

        return orders.compactMap { order in

            guard let rows = rowsByOrder[order.id] else {
                return nil
            }

            let studentOrders = rows.map(\.studentOrder)

            return LunchOrder(
                id: order.id,
                orderNumber: order.orderNumber,
                school: order.school,
                studentOrders: studentOrders,
                orderDate: order.orderDate,
                deliveryDate: order.deliveryDate,
                status: order.status,
                notes: order.notes
            )
        }
    }
    var runSheetOrders: [LunchOrder] {

        let rows = flattenedRows
            .filter {
                matchesDate($0) &&
                matchesSearch($0) &&
                matchesSchool($0)
            }

        let rowsByOrder = Dictionary(
            grouping: rows,
            by: \.orderID
        )

        return orders.compactMap { order in

            guard let rows = rowsByOrder[order.id] else {
                return nil
            }

            return LunchOrder(
                id: order.id,
                orderNumber: order.orderNumber,
                school: order.school,
                studentOrders: rows.map(\.studentOrder),
                orderDate: order.orderDate,
                deliveryDate: order.deliveryDate,
                status: order.status,
                notes: order.notes
            )
        }
    }
    
    var pastaReportOrders: [LunchOrder] {

        let rows = flattenedRows
            .filter {
                matchesDate($0)
            }

        let rowsByOrder = Dictionary(
            grouping: rows,
            by: \.orderID
        )

        return orders.compactMap { order in

            guard let rows = rowsByOrder[order.id] else {
                return nil
            }

            return LunchOrder(
                id: order.id,
                orderNumber: order.orderNumber,
                school: order.school,
                studentOrders: rows.map(\.studentOrder),
                orderDate: order.orderDate,
                deliveryDate: order.deliveryDate,
                status: order.status,
                notes: order.notes
            )
        }
    }

    var selectedOrdersForPrinting: [LunchOrder] {

        let selectedRows = filteredRows.filter {
            selectedPrintRowIDs.contains($0.id)
        }

        let rowsByOrder = Dictionary(
            grouping: selectedRows,
            by: \.orderID
        )

        return orders.compactMap { order in

            guard let rows = rowsByOrder[order.id] else {
                return nil
            }

            return LunchOrder(
                id: order.id,
                orderNumber: order.orderNumber,
                school: order.school,
                studentOrders: rows.map(\.studentOrder),
                orderDate: order.orderDate,
                deliveryDate: order.deliveryDate,
                status: order.status,
                notes: order.notes
            )
        }
    }
    var selectedRow: OrderBrowserRow? {
        guard let selectedRowID else { return filteredRows.first }
        return filteredRows.first { $0.id == selectedRowID } ?? filteredRows.first
    }

    var schoolOptions: [OrdersFilterOption] {
        [.all] + orders
            .filter { !$0.school.name.isEmpty }
            .map { OrdersFilterOption(id: $0.school.id.uuidString, title: $0.school.name) }
            .uniqued()
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var classOptions: [OrdersFilterOption] {
        [.all] + flattenedRows
            .compactMap { row -> OrdersFilterOption? in
                guard let schoolClass = row.studentOrder.schoolClass else { return nil }
                return OrdersFilterOption(id: schoolClass.id.uuidString, title: schoolClass.name)
            }
            .uniqued()
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var totalOrders: Int {
        Set(filteredRows.map(\.orderNumber)).count
    }

    var totalStudents: Int {
        filteredRows.count
    }

    var totalClasses: Int {
        Set(filteredRows.compactMap { $0.studentOrder.schoolClass?.id }).count
    }

    var totalMenuItems: Int {
        filteredRows.reduce(0) { total, row in
            total + row.studentOrder.items.reduce(0) { $0 + $1.quantity }
        }
    }
    func togglePrintSelection(_ row: OrderBrowserRow) {

        if selectedPrintRowIDs.contains(row.id) {
            selectedPrintRowIDs.remove(row.id)
        } else {
            selectedPrintRowIDs.insert(row.id)
        }
    }

    func selectAllVisible() {

        selectedPrintRowIDs = Set(
            filteredRows.map(\.id)
        )
    }

    func selectUnprintedHotLabels() {

        selectedPrintRowIDs = Set(
            filteredRows
                .filter { !$0.studentOrder.hotLabelPrinted }
                .map(\.id)
        )
    }

    func selectUnprintedColdLabels() {

        let labelService = LabelGenerationService()

        selectedPrintRowIDs = Set(
            filteredRows
                .filter { row in

                    guard !row.studentOrder.coldLabelPrinted else {
                        return false
                    }

                    guard let order = orders.first(
                        where: { $0.id == row.orderID }
                    ) else {
                        return false
                    }

                    let singleStudentOrder = LunchOrder(
                        id: order.id,
                        orderNumber: order.orderNumber,
                        school: order.school,
                        studentOrders: [row.studentOrder],
                        orderDate: order.orderDate,
                        deliveryDate: order.deliveryDate,
                        status: order.status,
                        notes: order.notes
                    )

                    return !labelService
                        .makeColdLabels(from: [singleStudentOrder])
                        .isEmpty
                }
                .map(\.id)
        )
    }

    func clearPrintSelection() {

        selectedPrintRowIDs.removeAll()
    }

    var selectedPrintCount: Int {

        filteredRows.filter {
            selectedPrintRowIDs.contains($0.id)
        }.count
    }
    var unprintedHotLabelCount: Int {

        filteredRows.filter {
            !$0.studentOrder.hotLabelPrinted
        }.count
    }
    var unprintedColdLabelCount: Int {

        let labelService = LabelGenerationService()

        return filteredRows.filter { row in

            guard !row.studentOrder.coldLabelPrinted else {
                return false
            }

            guard let order = orders.first(
                where: { $0.id == row.orderID }
            ) else {
                return false
            }

            let singleStudentOrder = LunchOrder(
                id: order.id,
                orderNumber: order.orderNumber,
                school: order.school,
                studentOrders: [row.studentOrder],
                orderDate: order.orderDate,
                deliveryDate: order.deliveryDate,
                status: order.status,
                notes: order.notes
            )

            return !labelService
                .makeColdLabels(from: [singleStudentOrder])
                .isEmpty
        }
        .count
    }

    func markSelectedHotLabelsPrinted() {

        guard !selectedPrintRowIDs.isEmpty else {
            return
        }

        for orderIndex in orders.indices {

            for studentIndex in orders[orderIndex].studentOrders.indices {

                let studentOrderID =
                    orders[orderIndex].studentOrders[studentIndex].id

                if selectedPrintRowIDs.contains(studentOrderID) {

                    orders[orderIndex]
                        .studentOrders[studentIndex]
                        .hotLabelPrinted = true
                }
            }
        }

        selectedPrintRowIDs.removeAll()
    }

    func markSelectedColdLabelsPrinted() {

        guard !selectedPrintRowIDs.isEmpty else {
            return
        }

        for orderIndex in orders.indices {

            for studentIndex in orders[orderIndex].studentOrders.indices {

                let studentOrderID =
                    orders[orderIndex].studentOrders[studentIndex].id

                if selectedPrintRowIDs.contains(studentOrderID) {

                    orders[orderIndex]
                        .studentOrders[studentIndex]
                        .coldLabelPrinted = true
                }
            }
        }

        selectedPrintRowIDs.removeAll()
    }
    func updateOrders(_ orders: [LunchOrder]) {
        self.orders = orders
        if !schoolOptions.contains(selectedSchool) {
            selectedSchool = .all
        }
        if !classOptions.contains(selectedClass) {
            selectedClass = .all
        }
        if let selectedRowID, flattenedRows.contains(where: { $0.id == selectedRowID }) {
            return
        }
        selectedRowID = flattenedRows.first?.id
    }

    private var flattenedRows: [OrderBrowserRow] {
        orders.flatMap { order in
            order.studentOrders.map { studentOrder in
                OrderBrowserRow(
                    orderID: order.id,
                    orderNumber: order.orderNumber,
                    school: order.school,
                    orderDate: order.orderDate,
                    deliveryDate: order.deliveryDate,
                    notes: order.notes,
                    studentOrder: studentOrder
                )
            }
        }
    }
    private func matchesDate(_ row: OrderBrowserRow) -> Bool {

        let calendar = Calendar.current
        let deliveryDate = row.deliveryDate

        switch dateView {

        case .today:
            return calendar.isDateInToday(deliveryDate)

        case .upcoming:
            let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: Date())
            )!

            return deliveryDate >= tomorrow

        case .history:
            return deliveryDate < calendar.startOfDay(for: Date())

        }

    }
    private func matchesSearch(_ row: OrderBrowserRow) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let searchableText = ([
            row.studentOrder.student.fullName,
            row.orderNumber,
            row.school.name,
            row.studentOrder.schoolClass?.name ?? "",
            row.notes ?? ""
        ] + row.studentOrder.items.flatMap { [$0.name] + $0.variants })
            .joined(separator: " ")

        return searchableText.localizedCaseInsensitiveContains(query)
    }

    private func matchesSchool(_ row: OrderBrowserRow) -> Bool {
        selectedSchool == .all || row.school.id.uuidString == selectedSchool.id
    }

    private func matchesClass(_ row: OrderBrowserRow) -> Bool {
        selectedClass == .all || row.studentOrder.schoolClass?.id.uuidString == selectedClass.id
    }
}

/// One visible row in the orders browser, representing one student's part of a Wix order.
struct OrderBrowserRow: Identifiable, Hashable, Sendable {
    var orderID: LunchOrder.ID
    var orderNumber: String
    var school: School
    var orderDate: Date
    var deliveryDate: Date
    var notes: String?
    var studentOrder: StudentOrder

    var id: StudentOrder.ID {
        studentOrder.id
    }
}

/// A selectable filter value for the orders browser.
struct OrdersFilterOption: Identifiable, Hashable, Sendable {
    static let all = OrdersFilterOption(id: "all", title: "All")

    var id: String
    var title: String
}

/// Supported sort modes for imported orders.
enum OrdersSortOption: String, CaseIterable, Identifiable, Sendable {
    case orderNumber = "Order Number"
    case student = "Student"
    case school = "School"
    case schoolClass = "Class"
    case orderDate = "Order Date"

    var id: String { rawValue }
}

private extension Array where Element == OrderBrowserRow {
    func sorted(using option: OrdersSortOption) -> [OrderBrowserRow] {
        switch option {
        case .orderNumber:
            sorted { $0.orderNumber.localizedStandardCompare($1.orderNumber) == .orderedAscending }
        case .student:
            sorted { $0.studentOrder.student.fullName.localizedCaseInsensitiveCompare($1.studentOrder.student.fullName) == .orderedAscending }
        case .school:
            sorted { $0.school.name.localizedCaseInsensitiveCompare($1.school.name) == .orderedAscending }
        case .schoolClass:
            sorted {
                ($0.studentOrder.schoolClass?.name ?? "")
                    .localizedCaseInsensitiveCompare($1.studentOrder.schoolClass?.name ?? "") == .orderedAscending
            }
        case .orderDate:
            sorted { $0.orderDate > $1.orderDate }
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
