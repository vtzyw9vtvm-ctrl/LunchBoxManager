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
    
    var selectedFirebaseDocumentIDs: [String] {

        Array(
            Set(
                flattenedRows.compactMap { row in

                    guard selectedPrintRowIDs.contains(row.id) else {
                        return nil
                    }

                    return row.firebaseDocumentID
                }
            )
        )
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
    var activeDeliveryDate: Date {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        func nextWeekday(after date: Date) -> Date {
            var nextDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: date
            )!

            while calendar.component(.weekday, from: nextDate) == 1 ||
                  calendar.component(.weekday, from: nextDate) == 7 {
                nextDate = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: nextDate
                )!
            }

            return nextDate
        }

        let todayAt2PM = calendar.date(
            bySettingHour: 14,
            minute: 0,
            second: 0,
            of: today
        )!

        if now >= todayAt2PM {
            return nextWeekday(after: today)
        }

        let weekday = calendar.component(
            .weekday,
            from: today
        )

        if weekday == 1 || weekday == 7 {
            return nextWeekday(after: today)
        }

        return today
    }
    
    private var flattenedRows: [OrderBrowserRow] {
        orders.flatMap { order in
            order.studentOrders.map { studentOrder in
                OrderBrowserRow(
                    orderID: order.id,
                    firebaseDocumentID: order.firebaseDocumentID,
                    orderNumber: order.orderNumber,
                    school: order.school,
                    orderDate: order.orderDate,
                    deliveryDate: order.deliveryDate,
                    status: order.status,
                    notes: order.notes,
                    studentOrder: studentOrder
                )
            }
        }
    }
    private func matchesDate(_ row: OrderBrowserRow) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        let today = calendar.startOfDay(for: now)

        // The cafe's operational lunch day rolls over at 2:00 PM.
        //
        // Before 2 PM:
        // Today = today's deliveries
        //
        // From 2 PM onward:
        // Today = tomorrow's deliveries
        let todayAt2PM = calendar.date(
            bySettingHour: 14,
            minute: 0,
            second: 0,
            of: today
        )!

        func nextWeekday(after date: Date) -> Date {
            var nextDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: date
            )!

            while calendar.component(
                .weekday,
                from: nextDate
            ) == 1 ||
            calendar.component(
                .weekday,
                from: nextDate
            ) == 7 {
                nextDate = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: nextDate
                )!
            }

            return nextDate
        }

        let activeDeliveryDay: Date

        if now >= todayAt2PM {
            activeDeliveryDay = nextWeekday(after: today)
        } else {
            // If the Manager is opened on a weekend,
            // show Monday as the active lunch day.
            let weekday = calendar.component(
                .weekday,
                from: today
            )

            if weekday == 1 || weekday == 7 {
                activeDeliveryDay = nextWeekday(after: today)
            } else {
                activeDeliveryDay = today
            }
        }

        let nextDeliveryDay =
            nextWeekday(after: activeDeliveryDay)

        let deliveryDay = calendar.startOfDay(
            for: row.deliveryDate
        )

        switch dateView {
        case .today:
            // Cancelled orders should no longer appear in today's
            // production list, even if their delivery date is today.
            guard row.status != .cancelled else {
                return false
            }

            return deliveryDay == activeDeliveryDay

        case .upcoming:
            // Cancelled future orders belong in History rather
            // than Upcoming.
            guard row.status != .cancelled else {
                return false
            }

            return deliveryDay >= nextDeliveryDay

        case .history:
            // A cancelled order is still an important business record.
            // Show it in History immediately, even if its delivery
            // date is today or in the future.
            if row.status == .cancelled {
                return true
            }

            return deliveryDay < activeDeliveryDay
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

/// One visible row in the orders browser, representing one student's order.
struct OrderBrowserRow: Identifiable, Hashable, Sendable {

    var orderID: LunchOrder.ID

    /// Original Firebase order document ID.
    /// Nil for local/sample/imported orders.
    var firebaseDocumentID: String?

    var orderNumber: String

    var school: School

    var orderDate: Date

    var deliveryDate: Date

    var status: LunchOrderStatus

    var notes: String?

    var studentOrder: StudentOrder

    var id: StudentOrder.ID {
        studentOrder.id
    }
}
/// A selectable filter value for the orders browser.
struct OrdersFilterOption: Identifiable, Hashable, Sendable {

    static let all = OrdersFilterOption(
        id: "all",
        title: "All"
    )

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
