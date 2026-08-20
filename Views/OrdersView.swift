import SwiftUI

/// Browse imported lunch orders before label generation.
struct OrdersView: View {

    @State private var viewModel: OrdersViewModel
    @State private var isLoadingFirebaseOrders = false

    private let firebaseOrderService = FirebaseOrderService()

    private let orders: [LunchOrder]
    private let onOrdersChanged: ([LunchOrder]) -> Void
    
    private let labelGenerationService = LabelGenerationService()
    private let labelPrintService = LabelPrintService()
    private let kitchenProductionListService = KitchenProductionListService()
    private let pastaPreparationReportService = PastaPreparationReportService()
    private let classPackingListService = ClassPackingListService()

    init(
        orders: [LunchOrder],
        onOrdersChanged: @escaping ([LunchOrder]) -> Void = { _ in }
    ) {

        self.orders = orders
        self.onOrdersChanged = onOrdersChanged

        _viewModel = State(
            initialValue: OrdersViewModel(
                orders: orders
            )
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            dateSelector
            deliveryDayHeader

            if viewModel.dateView == .today {
                productionActions
            }

            toolbar
            summaryStatistics
            ordersTable
            selectedOrderDetail
        }
        .padding(20)
        .navigationTitle("Orders")
        .searchable(
            text: $viewModel.searchText,
            prompt: "Student, order number, or menu item"
        )
        .task {
            await loadFirebaseOrders()
        }
    }
    
    private var dateSelector: some View {

        HStack {

            Text("School Orders")
                .font(.largeTitle.bold())

            Spacer()

            Picker("Orders", selection: $viewModel.dateView) {

                ForEach(OrdersDateView.allCases) { option in
                    Text(option.rawValue)
                        .tag(option)
                }

            }
            .pickerStyle(.segmented)
            .frame(width: 360)

        }

    }
    private func loadFirebaseOrders() async {
        guard !isLoadingFirebaseOrders else {
            return
        }

        isLoadingFirebaseOrders = true

        do {
            let firebaseOrders = try await firebaseOrderService.loadOrders()

            viewModel.updateOrders(firebaseOrders)

            print("🔥 FIREBASE ORDERS LOADED:", firebaseOrders.count)
        } catch {
            print("🔥 FIREBASE ORDERS ERROR:", error.localizedDescription)
        }

        isLoadingFirebaseOrders = false
    }
    private var deliveryDayHeader: some View {

        HStack {

            VStack(alignment: .leading, spacing: 4) {

                switch viewModel.dateView {

                case .today:

                    Text("Today's Lunch Orders")
                        .font(.title2.bold())

                    Text(
                        Date.now.formatted(
                            .dateTime
                                .weekday(.wide)
                                .day()
                                .month(.wide)
                                .year()
                        )
                    )
                    .foregroundStyle(.secondary)

                case .upcoming:

                    Text("Upcoming Lunch Orders")
                        .font(.title2.bold())

                    Text("Orders for future delivery dates")
                        .foregroundStyle(.secondary)

                case .history:

                    Text("Order History")
                        .font(.title2.bold())

                    Text("Previous school lunch orders")
                        .foregroundStyle(.secondary)

                }

            }

            Spacer()

            if viewModel.dateView == .today {

                VStack(alignment: .trailing, spacing: 4) {

                    Text("\(viewModel.totalStudents) Lunches")
                        .font(.headline)

                    Text("Ordering closes at 8:30 AM")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                }

            }

        }
        .padding(.vertical, 4)

    }
    private var productionActions: some View {

        HStack(spacing: 12) {
            
            Button("Select Unprinted") {
                viewModel.selectUnprintedHotLabels()
            }
            .buttonStyle(.bordered)

            Button("Select All") {
                viewModel.selectAllVisible()
            }
            .buttonStyle(.bordered)

            Button("Clear") {
                viewModel.clearPrintSelection()
            }
            .buttonStyle(.bordered)

            Divider()
                .frame(height: 24)

            Button {
                
                viewModel.selectUnprintedHotLabels()

                let labels = labelGenerationService.makeHotLabels(
                    from: viewModel.selectedOrdersForPrinting
                )

                let document = labelGenerationService.makePDFDocument(
                    for: labels
                )

                let didPrint = labelPrintService.printLabels(
                    document: document,
                    jobTitle: "Hot Lunch Labels"
                )

                if didPrint {
                    viewModel.markSelectedColdLabelsPrinted()
                    onOrdersChanged(viewModel.allOrders)
                }

            } label: {

                Label(
                    "Hot Labels (\(viewModel.unprintedHotLabelCount))",
                    systemImage: "flame.fill"
                )

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {

                if viewModel.selectedPrintCount == 0 {
                    viewModel.selectUnprintedColdLabels()
                }

                let labels = labelGenerationService.makeColdLabels(
                    from: viewModel.selectedOrdersForPrinting
                )

                let document = labelGenerationService.makePDFDocument(
                    for: labels
                )

                let didPrint = labelPrintService.printLabels(
                    document: document,
                    jobTitle: "Cold Lunch Labels"
                )

                if didPrint {
                    viewModel.markSelectedColdLabelsPrinted()
                    onOrdersChanged(viewModel.allOrders)
                }

            } label: {

                Label(
                    "Cold Labels (\(viewModel.unprintedColdLabelCount))",
                    systemImage: "snowflake"
                )

            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {

                let reports = kitchenProductionListService.makeReports(
                    from: viewModel.runSheetOrders
                )

                for report in reports {

                    labelPrintService.printDocument(
                        document: report.document,
                        jobTitle: "\(report.schoolName) Run Sheet"
                    )
                }

            } label: {

                Label(
                    "Run Sheets",
                    systemImage: "checklist"
                )

            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Button {

                let reports = pastaPreparationReportService.makeReports(
                    from: viewModel.pastaReportOrders
                )

                for report in reports {

                    labelPrintService.printDocument(
                        document: report.document,
                        jobTitle: report.reportName
                    )
                }

            } label: {

                Label(
                    "Pasta Report",
                    systemImage: "fork.knife"
                )

            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Button {

                let reports = classPackingListService.makeReports(
                    from: viewModel.pastaReportOrders
                )

                for report in reports {

                    labelPrintService.printA5Document(
                        document: report.document,
                        jobTitle: "\(report.schoolName) Class Packing List"
                    )
                }

            } label: {

                Label(
                    "Class Packing Lists",
                    systemImage: "list.clipboard"
                )

            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Spacer()

        }

    }
    private var toolbar: some View {
        HStack(spacing: 12) {
            Picker("School", selection: $viewModel.selectedSchool) {
                ForEach(viewModel.schoolOptions) { option in
                    Text(option.title).tag(option)
                }
            }
            .frame(maxWidth: 220)

            Picker("Class", selection: $viewModel.selectedClass) {
                ForEach(viewModel.classOptions) { option in
                    Text(option.title).tag(option)
                }
            }
            .frame(maxWidth: 180)

            Spacer()

            Picker("Sort", selection: $viewModel.sortOption) {
                ForEach(OrdersSortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .frame(maxWidth: 180)
        }
        .pickerStyle(.menu)
    }

    private var summaryStatistics: some View {
        HStack(spacing: 12) {
            CompactStatisticView(title: "Orders", value: viewModel.totalOrders)
            CompactStatisticView(title: "Students", value: viewModel.totalStudents)
            CompactStatisticView(title: "Classes", value: viewModel.totalClasses)
            CompactStatisticView(title: "Menu Items", value: viewModel.totalMenuItems)
        }
    }

    private var ordersTable: some View {

        Table(
            viewModel.filteredRows,
            selection: $viewModel.selectedRowID
        ) {

            // MARK: Selection

            TableColumn("") { row in

                Button {

                    viewModel.togglePrintSelection(row)

                } label: {

                    Image(
                        systemName: viewModel.selectedPrintRowIDs.contains(row.id)
                            ? "checkmark.square.fill"
                            : "square"
                    )
                    .font(.system(size: 16))

                }
                .buttonStyle(.plain)
            }
            .width(28)


            // MARK: Order Number

            TableColumn("Order Number") { row in
                Text(row.orderNumber)
            }
            .width(min: 90, ideal: 100)


            // MARK: Date

            TableColumn("Date") { row in
                Text(
                    row.deliveryDate.formatted(
                        .dateTime
                            .day()
                            .month(.abbreviated)
                    )
                )
            }
            .width(min: 60, ideal: 70)


            // MARK: Student

            TableColumn("Student") { row in
                Text(row.studentOrder.student.fullName)
            }
            .width(min: 110, ideal: 150)


            // MARK: Class

            TableColumn("Class") { row in
                Text(row.studentOrder.schoolClass?.name ?? "—")
            }
            .width(min: 50, ideal: 65)


            // MARK: Items

            TableColumn("Items") { row in
                Text(
                    row.studentOrder.items
                        .map(\.displaySummary)
                        .joined(separator: ", ")
                )
                .lineLimit(1)
            }
            .width(min: 180, ideal: 300)


            // MARK: Notes

            TableColumn("Notes") { row in
                Text(row.notes ?? "")
                    .lineLimit(1)
            }
            .width(min: 140, ideal: 240)


            // MARK: School

            TableColumn("School") { row in

                Text(
                    row.school.shortName.isEmpty
                        ? "—"
                        : row.school.shortName
                )
            }
            .width(min: 45, ideal: 55)


            // MARK: Printed

            TableColumn("Printed") { row in

                HStack(spacing: 5) {

                    if row.studentOrder.hotLabelPrinted {

                        Label(
                            "Hot",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)
                    }

                    if row.studentOrder.coldLabelPrinted {

                        Label(
                            "Cold",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.blue)
                    }

                    if !row.studentOrder.hotLabelPrinted &&
                        !row.studentOrder.coldLabelPrinted {

                        Text("—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .width(min: 65, ideal: 90)
        }
        .overlay {

            if viewModel.filteredRows.isEmpty {

                ContentUnavailableView(
                    "No Orders",
                    systemImage: "tray",
                    description: Text(
                        "No imported orders match the current search and filters."
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var selectedOrderDetail: some View {
        if let selectedRow = viewModel.selectedRow {
            OrderDetailView(row: selectedRow)
        }
    }
}

private struct OrderDetailView: View {
    var row: OrderBrowserRow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OrderRowView(row: row)

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                DetailRow(
                    title: "Student",
                    value: row.studentOrder.student.fullName.isEmpty ? "Not specified" : row.studentOrder.student.fullName
                )
                DetailRow(title: "School", value: row.school.name.isEmpty ? "Not specified" : row.school.name)
                DetailRow(title: "Class", value: row.studentOrder.schoolClass?.name ?? "Not specified")
                DetailRow(title: "Order Number", value: row.orderNumber)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Menu Items")
                    .font(.headline)

                ForEach(row.studentOrder.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(item.quantity)x \(item.name)")
                        if !item.variants.isEmpty {
                            Text("Choice: \(item.variants.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let notes = row.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DetailRow: View {
    var title: String
    var value: String

    var body: some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}

private extension MenuItem {
    var displaySummary: String {
        let choice = variants.first.map { " (\($0))" } ?? ""
        return "\(quantity)x \(name)\(choice)"
    }
}

private struct CompactStatisticView: View {
    var title: String
    var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value, format: .number)
                .font(.title2.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    OrdersView(orders: SampleDataService().makeSampleImport().orders)
}
