import SwiftUI

/// Browse imported lunch orders before label generation.
struct OrdersView: View {
    @State private var viewModel: OrdersViewModel
    private let orders: [LunchOrder]

    init(orders: [LunchOrder]) {
        self.orders = orders
        _viewModel = State(initialValue: OrdersViewModel(orders: orders))
    }

    var body: some View {
        VStack(spacing: 16) {
            toolbar
            summaryStatistics
            ordersTable
            selectedOrderDetail
        }
        .padding(20)
        .navigationTitle("Orders")
        .searchable(text: $viewModel.searchText, prompt: "Student, order number, or menu item")
        .onChange(of: orders) { _, newOrders in
            viewModel.updateOrders(newOrders)
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
        Table(viewModel.filteredRows, selection: $viewModel.selectedRowID) {
            TableColumn("Order Number") { row in
                Text(row.orderNumber)
            }
            TableColumn("Student") { row in
                Text(row.studentOrder.student.fullName)
            }
            TableColumn("School") { row in
                Text(row.school.name.isEmpty ? "Not specified" : row.school.name)
            }
            TableColumn("Class") { row in
                Text(row.studentOrder.schoolClass?.name ?? "Not specified")
            }
            TableColumn("Items") { row in
                Text(row.studentOrder.items.map(\.displaySummary).joined(separator: ", "))
                    .lineLimit(1)
            }
            TableColumn("Notes") { row in
                Text(row.notes ?? "")
                    .lineLimit(1)
            }
        }
        .overlay {
            if viewModel.filteredRows.isEmpty {
                ContentUnavailableView(
                    "No Orders",
                    systemImage: "tray",
                    description: Text("No imported orders match the current search and filters.")
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
