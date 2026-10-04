import SwiftUI
import FirebaseFirestore

/// Browse imported lunch orders before label generation.
struct OrdersView: View {

    @State private var viewModel: OrdersViewModel

    @State private var isLoadingFirebaseOrders = false

    @State private var orderListener: ListenerRegistration?

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
        VStack(spacing: 0) {

            PageBannerView(
                title: "School Orders",
                subtitle: "View and manage school lunch orders",
                systemImage: "bag.fill",
                color: .lunchBoxOrangeBrown
            )

            VStack(spacing: 16) {

                dateSelector

                deliveryDayHeader

                productionActions

                toolbar

                summaryStatistics

                ordersTable
                    .frame(minHeight: 120, idealHeight: 300, maxHeight: 420)

                selectedOrderDetail

            }
            .padding(20)

        }
        .navigationTitle("Orders")
        .task {
            await loadFirebaseOrders()
            startListeningForOrders()
        }
        .onDisappear {
            orderListener?.remove()
            orderListener = nil
        }
    }
    
    private var dateSelector: some View {

        HStack {

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
    
    private func startListeningForOrders() {

        // Prevent accidentally creating more than one listener.
        guard orderListener == nil else {
            return
        }

        orderListener = firebaseOrderService.listenForOrderChanges(
            onChange: { firebaseOrders in

                viewModel.updateOrders(firebaseOrders)

                print(
                    "🔥 LIVE FIREBASE ORDERS UPDATED:",
                    firebaseOrders.count
                )
            },
            onError: { error in

                print(
                    "🔥 LIVE FIREBASE ORDERS ERROR:",
                    error.localizedDescription
                )
            }
        )
    }
    
    private var deliveryDayHeader: some View {

        HStack {

            VStack(alignment: .leading, spacing: 4) {

                switch viewModel.dateView {

                case .today:

                    Text("Today's Lunch Orders")
                        .font(.title2.bold())

                    Text(
                        viewModel.activeDeliveryDate.formatted(
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

            Button {
                // If orders have been manually ticked, print only those orders.
                // Otherwise print the normal batch of unprinted hot labels.
                let isManualReprint = !viewModel.selectedPrintRowIDs.isEmpty

                if !isManualReprint {
                    viewModel.selectUnprintedHotLabels()
                }

                let firebaseDocumentIDs = viewModel.selectedFirebaseDocumentIDs

                let labels = labelGenerationService.makeHotLabels(
                    from: viewModel.selectedOrdersForPrinting
                )

                let document = labelGenerationService.makePDFDocument(
                    for: labels
                )

                let didPrint = labelPrintService.printLabels(
                    document: document,
                    jobTitle: isManualReprint
                        ? "Reprint Hot Lunch Labels"
                        : "Hot Lunch Labels"
                )

                if didPrint {
                    // Normal batch printing marks the labels as printed.
                    //
                    // A manual reprint does NOT alter the existing print status.
                    if !isManualReprint {
                        viewModel.markSelectedHotLabelsPrinted()
                        onOrdersChanged(viewModel.allOrders)

                        Task {
                            for documentID in firebaseDocumentIDs {
                                do {
                                    try await firebaseOrderService.markHotLabelPrinted(
                                        orderID: documentID
                                    )

                                    print(
                                        "🔥 HOT PRINT STATUS SAVED:",
                                        documentID
                                    )
                                } catch {
                                    print(
                                        "🔥 FAILED TO UPDATE HOT PRINT STATUS:",
                                        documentID,
                                        error.localizedDescription
                                    )
                                }
                            }
                        }
                    }
                }
            } label: {
                Label(
                    "Bag Labels (\(viewModel.unprintedHotLabelCount))",
                    systemImage: "bag.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.lunchBoxGreen)
            .controlSize(.large)

            Button {
                // If orders have been manually ticked, print cold labels
                // only for those selected orders.
                // Otherwise print the normal batch of unprinted cold labels.
                let isManualReprint = !viewModel.selectedPrintRowIDs.isEmpty

                if !isManualReprint {
                    viewModel.selectUnprintedColdLabels()
                }

                let firebaseDocumentIDs = viewModel.selectedFirebaseDocumentIDs

                let labels = labelGenerationService.makeColdLabels(
                    from: viewModel.selectedOrdersForPrinting
                )

                let document = labelGenerationService.makePDFDocument(
                    for: labels
                )

                let didPrint = labelPrintService.printLabels(
                    document: document,
                    jobTitle: isManualReprint
                        ? "Reprint Cold Lunch Labels"
                        : "Cold Lunch Labels"
                )

                if didPrint {
                    // Normal batch printing marks the labels as printed.
                    //
                    // A manual reprint does NOT alter the existing print status.
                    if !isManualReprint {
                        viewModel.markSelectedColdLabelsPrinted()
                        onOrdersChanged(viewModel.allOrders)

                        Task {
                            for documentID in firebaseDocumentIDs {
                                do {
                                    try await firebaseOrderService.markColdLabelPrinted(
                                        orderID: documentID
                                    )

                                    print(
                                        "🔥 COLD PRINT STATUS SAVED:",
                                        documentID
                                    )
                                } catch {
                                    print(
                                        "🔥 FAILED TO UPDATE COLD PRINT STATUS:",
                                        documentID,
                                        error.localizedDescription
                                    )
                                }
                            }
                        }
                    }
                }
            } label: {
                Label(
                    "Cold Bag Labels (\(viewModel.unprintedColdLabelCount))",
                    systemImage: "snowflake"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue.opacity(0.65))
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
            .buttonStyle(.borderedProminent)
            .tint(.lunchBoxPurple)
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
            .buttonStyle(.borderedProminent)
            .tint(
                Color(
                    red: 0.72,
                    green: 0.62,
                    blue: 0.48
                )
            )
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
            .buttonStyle(.borderedProminent)
            .tint(
                Color(
                    red: 0.78,
                    green: 0.48,
                    blue: 0.58
                )
            )
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

            TableColumn("Order No.") { row in
                Text(formattedOrderNumber(row.orderNumber))
            }
            .width(min: 60, ideal: 60)


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
            .width(min: 50, ideal: 50)


            // MARK: Student

            TableColumn("Student") { row in
                Text(row.studentOrder.student.fullName)
            }
            .width(min: 90, ideal: 120)


            // MARK: Class

            TableColumn("Class") { row in
                Text(row.studentOrder.schoolClass?.name ?? "—")
            }
            .width(min: 50, ideal: 50)


            // MARK: Items

            TableColumn("Items") { row in
                Text(
                    row.studentOrder.items
                        .map(\.displaySummary)
                        .joined(separator: ", ")
                )
                .lineLimit(1)
            }
            .width(min: 150, ideal: 280)


            // MARK: Notes

            TableColumn("Notes") { row in
                let itemNotes = row.studentOrder.items
                    .compactMap { $0.notes }
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                let allNotes = itemNotes.joined(separator: " • ")

                Text(allNotes.isEmpty ? (row.notes ?? "") : allNotes)
                    .lineLimit(1)
            }
            .width(min: 110, ideal: 200)


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
            OrderDetailView(
                row: selectedRow,
                allOrders: viewModel.allOrders
            )
        }
    }
}

private struct OrderDetailView: View {

    var row: OrderBrowserRow
    var allOrders: [LunchOrder]

    @State private var showingRefundSheet = false
    @State private var showingParentHistory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            if row.status == .cancelled {
                Text("CANCELLED • REFUNDED")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Color.red,
                        in: Capsule()
                    )
            }

            HStack(spacing: 24) {
                HStack(spacing: 5) {
                    Text("Student:")
                        .foregroundStyle(.secondary)
                    Text(
                        row.studentOrder.student.fullName.isEmpty
                            ? "Not specified"
                            : row.studentOrder.student.fullName
                    )
                    .fontWeight(.medium)
                }

                HStack(spacing: 5) {
                    Text("School:")
                        .foregroundStyle(.secondary)
                    Text(
                        row.school.name.isEmpty
                            ? "Not specified"
                            : row.school.name
                    )
                    .fontWeight(.medium)
                }

                HStack(spacing: 5) {
                    Text("Class:")
                        .foregroundStyle(.secondary)
                    Text(
                        row.studentOrder.schoolClass?.name
                            ?? "Not specified"
                    )
                    .fontWeight(.medium)
                }

                HStack(spacing: 5) {
                    Text("Order No:")
                        .foregroundStyle(.secondary)
                    Text(formattedOrderNumber(row.orderNumber))
                        .fontWeight(.medium)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Menu Items")
                    .font(.headline)

                ForEach(row.studentOrder.items) { item in
                    VStack(alignment: .leading, spacing: 4) {

                        HStack(spacing: 8) {
                            Text("\(item.quantity)x \(item.name)")
                                .strikethrough(
                                    item.refundedQuantity >= item.quantity
                                )
                                .foregroundStyle(
                                    item.refundedQuantity >= item.quantity
                                        ? .secondary
                                        : .primary
                                )

                            if item.refundedQuantity > 0 {
                                Text(
                                    item.refundedQuantity >= item.quantity
                                        ? "REFUNDED — \(item.refundedAmount, format: .currency(code: "AUD"))"
                                        : "\(item.refundedQuantity) REFUNDED — \(item.refundedAmount, format: .currency(code: "AUD"))"
                                )
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                            }
                        }

                        if !item.variants.isEmpty {
                            Text("Choice: \(item.variants.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let notes = item.notes,
                           !notes.isEmpty {
                            Text("Special Instructions: \(notes)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
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

            Divider()

            HStack {

                Spacer()

                Button {
                    showingParentHistory = true
                } label: {
                    Label(
                        "Parent Order History",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(row.parentId == nil)

                Button {
                    showingRefundSheet = true
                } label: {
                    Label(
                        "Refund Items",
                        systemImage: "arrow.uturn.backward.circle"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(
                    row.status == .cancelled ||
                    row.firebaseDocumentID == nil ||
                    row.studentOrder.items.allSatisfy {
                        $0.firebaseOrderItemID == nil
                    }
                )
            }

            }
            .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .sheet(isPresented: $showingRefundSheet) {
            RefundItemsSheet(row: row)
        }
        .sheet(isPresented: $showingParentHistory) {
            ParentOrderHistorySheet(
                parentId: row.parentId,
                parentEmail: row.parentEmail,
                allOrders: allOrders
            )
        }
            }

        }

private struct ParentOrderHistorySheet: View {
    let parentId: String?
    let parentEmail: String?
    let allOrders: [LunchOrder]

    @Environment(\.dismiss) private var dismiss

    private var parentOrders: [LunchOrder] {
        guard let parentId, !parentId.isEmpty else {
            return []
        }

        return allOrders
            .filter { $0.parentId == parentId }
            .sorted { $0.orderDate > $1.orderDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parent Order History")
                        .font(.title2.bold())

                    if let parentEmail, !parentEmail.isEmpty {
                        Text(parentEmail)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }

            Divider()

            if parentOrders.isEmpty {
                ContentUnavailableView(
                    "No Previous Orders",
                    systemImage: "clock.arrow.circlepath",
                    description: Text(
                        "No order history was found for this parent."
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(parentOrders) { order in
                            orderCard(order)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 500)
    }

    @ViewBuilder
    private func orderCard(_ order: LunchOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Order #\(formattedOrderNumber(order.orderNumber))")
                    .font(.headline)

                Spacer()

                Text(
                    order.deliveryDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .fontWeight(.semibold)
            }

            HStack(spacing: 20) {
                Label(
                    order.school.name,
                    systemImage: "building.2"
                )

                Text(order.status.title)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            ForEach(order.studentOrders) { studentOrder in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(studentOrder.student.fullName)
                            .fontWeight(.semibold)

                        if let schoolClass = studentOrder.schoolClass {
                            Text("• \(schoolClass.name)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(studentOrder.items) { item in
                        HStack(alignment: .top) {
                            Text("\(item.quantity)×")
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)

                                if !item.variants.isEmpty {
                                    Text(item.variants.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}

private struct RefundItemsSheet: View {

    let row: OrderBrowserRow

    @Environment(\.dismiss) private var dismiss

    @State private var selectedItemIDs: Set<UUID> = []
    @State private var refundQuantities: [UUID: Int] = [:]

    @State private var showingConfirmation = false
    @State private var isRefunding = false
    @State private var refundError: String?
    @State private var activeRefundRequestId: String?

    private var selectedCount: Int {
        selectedItemIDs.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Refund Items")
                        .font(.title2.bold())

                    Text(
                        "Order #\(formattedOrderNumber(row.orderNumber)) — \(row.studentOrder.student.fullName)"
                    )
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    ForEach(row.studentOrder.items) { item in
                        refundItemRow(item)
                    }
                }
            }

            Divider()

            HStack {
                Text(
                    selectedCount == 0
                        ? "Select the items to refund."
                        : "\(selectedCount) item\(selectedCount == 1 ? "" : "s") selected"
                )
                .foregroundStyle(.secondary)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Continue") {
                    showingConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    selectedItemIDs.isEmpty ||
                    isRefunding
                )
            }
        }
        .padding(24)
        .frame(
            minWidth: 520,
            idealWidth: 580,
            minHeight: 360,
            idealHeight: 460
        )
        
        .confirmationDialog(
            "Confirm Refund",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Refund Selected Items", role: .destructive) {
                Task {
                    await performRefund()
                }
            }

            Button("Cancel", role: .cancel) {
            }
        } message: {
            Text(refundConfirmationMessage)
        }
        .alert(
            "Refund Failed",
            isPresented: Binding(
                get: { refundError != nil },
                set: { newValue in
                    if !newValue {
                        refundError = nil
                    }
                }
            )
        ) {
            Button("OK") {
                refundError = nil
            }
        } message: {
            Text(refundError ?? "")
        }
    }

    @ViewBuilder
    private func refundItemRow(
        _ item: MenuItem
    ) -> some View {

        let isSelected =
            selectedItemIDs.contains(item.id)

        let remainingQuantity =
            item.activeQuantity

        let isFullyRefunded =
            remainingQuantity == 0

        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .top, spacing: 12) {

                Button {
                    toggleItem(item)
                } label: {
                    Image(
                        systemName: isFullyRefunded
                            ? "checkmark.square.fill"
                            : (
                                isSelected
                                    ? "checkmark.square.fill"
                                    : "square"
                            )
                    )
                    .font(.system(size: 18))
                    .foregroundStyle(
                        isFullyRefunded
                            ? .secondary
                            : .primary
                    )
                }
                .buttonStyle(.plain)
                .disabled(isFullyRefunded)

                VStack(alignment: .leading, spacing: 4) {

                    HStack(spacing: 8) {

                        Text(item.name)
                            .fontWeight(.semibold)
                            .strikethrough(isFullyRefunded)
                            .foregroundStyle(
                                isFullyRefunded
                                    ? .secondary
                                    : .primary
                            )

                        if isFullyRefunded {
                            Text("REFUNDED")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                    }

                    if !item.variants.isEmpty {
                        Text(
                            item.variants.joined(
                                separator: ", "
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if item.refundedQuantity > 0 {

                        if isFullyRefunded {
                            Text(
                                "Ordered: \(item.quantity) • Refunded: \(item.refundedQuantity) • Remaining: 0"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        } else {
                            Text(
                                "Ordered: \(item.quantity) • Refunded: \(item.refundedQuantity) • Remaining: \(remainingQuantity)"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                    } else {

                        Text(
                            item.quantity == 1
                                ? "Quantity: 1"
                                : "Quantity: \(item.quantity)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected &&
                    remainingQuantity > 1 {

                    Stepper(
                        value: quantityBinding(for: item),
                        in: 1...remainingQuantity
                    ) {
                        Text(
                            "Refund \(refundQuantities[item.id] ?? 1)"
                        )
                    }
                    .fixedSize()
                }
            }
            .contentShape(Rectangle())
        }
        .padding(12)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .opacity(isFullyRefunded ? 0.7 : 1)
    }

    private func toggleItem(
        _ item: MenuItem
    ) {
        guard item.activeQuantity > 0 else {
            return
        }
        activeRefundRequestId = nil
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
            refundQuantities[item.id] = nil
        } else {
            selectedItemIDs.insert(item.id)
            refundQuantities[item.id] = 1
        }
    }

    private func quantityBinding(
        for item: MenuItem
    ) -> Binding<Int> {
        Binding(
            get: {
                refundQuantities[item.id] ?? 1
            },
            set: { newValue in
                activeRefundRequestId = nil
                refundQuantities[item.id] =
                    newValue
            }
        )
    }

    private var refundConfirmationMessage: String {
        let selectedItems =
            row.studentOrder.items.filter {
                selectedItemIDs.contains($0.id)
            }

        let descriptions =
            selectedItems.map { item in
                let quantity =
                    refundQuantities[item.id] ?? 1

                return quantity == 1
                    ? item.name
                    : "\(quantity)x \(item.name)"
            }

        return """
        You are about to refund:

        \(descriptions.joined(separator: "\n"))

        This will issue a real Stripe refund. This cannot be undone.
        """
    }

    @MainActor
    private func performRefund() async {

        guard !isRefunding else {
            return
        }

        guard let orderId =
                row.firebaseDocumentID else {
            refundError =
                "This order does not have a Firebase order ID."
            return
        }

        let selectedItems =
            row.studentOrder.items.filter {
                selectedItemIDs.contains($0.id)
            }

        var refundItems:
            [(itemId: String, quantity: Int)] = []

        for item in selectedItems {

            guard let firebaseItemID =
                    item.firebaseOrderItemID else {
                refundError =
                    "\(item.name) does not have a Firebase order item ID."
                return
            }

            let quantity =
                refundQuantities[item.id] ?? 1

            refundItems.append(
                (
                    itemId: firebaseItemID,
                    quantity: quantity
                )
            )
        }

        guard !refundItems.isEmpty else {
            refundError =
                "No refundable items were selected."
            return
        }

        let refundRequestId: String

        if let existingRequestId =
            activeRefundRequestId {

            refundRequestId =
                existingRequestId

        } else {

            let newRequestId =
                UUID().uuidString

            activeRefundRequestId =
                newRequestId

            refundRequestId =
                newRequestId
        }

        isRefunding = true
        refundError = nil

        do {
            let service = FirebaseOrderService()

            let result =
                try await service.refundOrderItems(
                    orderId: orderId,
                    refundRequestId: refundRequestId,
                    items: refundItems
                )

            let amount =
                (result["refundAmount"] as? NSNumber)?
                    .doubleValue ?? 0

            print(
                "✅ ITEM REFUND SUCCESS:",
                String(format: "$%.2f", amount)
            )

            activeRefundRequestId = nil
            isRefunding = false
            dismiss()

        } catch {
            isRefunding = false
            refundError =
                error.localizedDescription
        }
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
private func formattedOrderNumber(_ orderNumber: String) -> String {
    guard let number = Int(orderNumber) else {
        return orderNumber
    }

    return String(format: "%05d", number)
}
#Preview {
    OrdersView(orders: SampleDataService().makeSampleImport().orders)
}
