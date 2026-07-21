import AppKit
import PDFKit
import SwiftUI

struct ContentView: View {
    @State private var importViewModel = ImportViewModel()
    @State private var selectedScreen: AppScreen? = .dashboard
    @State private var previewDocuments: [AppPreviewDocument] = []
    @State private var statusMessages: [String] = []
    @State private var isShowingStatusPanel = false

    private let labelGenerationService = LabelGenerationService()
    private let kitchenProductionListService = KitchenProductionListService()
    private let classPackingListService = ClassPackingListService()

    var body: some View {
        NavigationSplitView {
            List(AppScreen.allCases, selection: $selectedScreen) { screen in
                Label(screen.title, systemImage: screen.systemImage)
                    .tag(screen)
            }
            .navigationTitle("School Lunch Manager")
        } detail: {
            detailView
                .background(AppTheme.appBackground)
        }
        .navigationTitle("School Lunch Manager")
        .tint(AppTheme.primary)
        .frame(minWidth: 1120, minHeight: 720)
        .background(previewPresenters)
        .overlay(alignment: .topTrailing) {
            if isShowingStatusPanel {
                StatusPanel(messages: statusMessages) {
                    isShowingStatusPanel = false
                }
                .padding(24)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert(
            "Import Failed",
            isPresented: Binding(
                get: { importViewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        importViewModel.dismissImportError()
                    }
                }
            )
        ) {
            Button("OK") {
                importViewModel.dismissImportError()
            }
        } message: {
            Text(importViewModel.errorMessage ?? "The selected CSV could not be imported.")
        }
        .alert(
            "Import Complete",
            isPresented: Binding(
                get: { importViewModel.importCompleteMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        importViewModel.dismissImportCompleteMessage()
                    }
                }
            )
        ) {
            Button("OK") {
                importViewModel.dismissImportCompleteMessage()
            }
        } message: {
            Text(importViewModel.importCompleteMessage ?? "Import complete.")
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedScreen ?? .dashboard {
        case .dashboard:
            DashboardHomeView(
                viewModel: importViewModel,
                selectScreen: { selectedScreen = $0 },
                importCSV: importCSV,
                generatePack: generateTodayPack,
                generateHotLabels: generateHotLabels,
                generateColdLabels: generateColdLabels,
                generateKitchenProduction: generateKitchenProductionLists,
                generateClassPacking: generateClassPackingLists
            )
        case .importCSV:
            ImportCSVView(viewModel: importViewModel, importCSV: importCSV)
        case .labels:
            LabelsView(orders: importViewModel.importedOrders)
        case .kitchenProduction:
            SingleReportView(
                title: "Kitchen Production",
                subtitle: "Generate menu-item production lists for each school.",
                buttonTitle: "Generate Kitchen Production Lists",
                systemImage: "fork.knife",
                orders: importViewModel.importedOrders,
                generatedCount: kitchenReportCount,
                action: generateKitchenProductionLists
            )
        case .classPacking:
            SingleReportView(
                title: "Class Packing Lists",
                subtitle: "Generate one A5 packing page per class, separated by school.",
                buttonTitle: "Generate Class Packing Lists",
                systemImage: "shippingbox",
                orders: importViewModel.importedOrders,
                generatedCount: classPackingReportCount,
                action: generateClassPackingLists
            )
        case .settings:
            SettingsView()
        case .about:
            AboutView()
        }
    }

    private var previewPresenters: some View {
        ForEach(previewDocuments.indices, id: \.self) { index in
            LabelsPreviewWindowPresenter(
                isPresented: Binding(
                    get: { previewDocuments.indices.contains(index) && previewDocuments[index].isPresented },
                    set: { isPresented in
                        guard previewDocuments.indices.contains(index) else { return }
                        previewDocuments[index].isPresented = isPresented
                    }
                ),
                title: previewDocuments[index].title,
                document: previewDocuments[index].document
            )
            .frame(width: 0, height: 0)
        }
    }

    private var kitchenReportCount: Int {
        Set(importViewModel.importedOrders.map(\.school.id)).count
    }

    private var classPackingReportCount: Int {
        Set(importViewModel.importedOrders.map(\.school.id)).count
    }

    private func importCSV() {
        Task {
            await importViewModel.chooseAndImportCSVFile()
        }
    }

    private func generateHotLabels() {
        let labels = labelGenerationService.makeHotLabels(from: importViewModel.importedOrders)
        guard !labels.isEmpty else { return }

        previewDocuments = [
            AppPreviewDocument(
                title: "Hot Labels Preview",
                document: labelGenerationService.makePDFDocument(for: labels)
            )
        ]
        showStatus(["Hot Labels created"])
    }

    private func generateColdLabels() {
        let labels = labelGenerationService.makeColdLabels(from: importViewModel.importedOrders)
        guard !labels.isEmpty else { return }

        previewDocuments = [
            AppPreviewDocument(
                title: "Cold Labels Preview",
                document: labelGenerationService.makePDFDocument(for: labels)
            )
        ]
        showStatus(["Cold Labels created"])
    }

    private func generateKitchenProductionLists() {
        let reports = kitchenProductionListService.makeReports(from: importViewModel.importedOrders)
        guard !reports.isEmpty else { return }

        previewDocuments = reports.map { report in
            AppPreviewDocument(
                title: "Kitchen Production List - \(report.schoolName)",
                document: report.document
            )
        }
        showStatus(["Kitchen Production List created"])
    }

    private func generateClassPackingLists() {
        let reports = classPackingListService.makeReports(from: importViewModel.importedOrders)
        guard !reports.isEmpty else { return }

        previewDocuments = reports.map { report in
            AppPreviewDocument(
                title: "Class Packing List - \(report.schoolName)",
                document: report.document
            )
        }
        showStatus(["Class Packing Lists created"])
    }

    private func generateTodayPack() {
        var documents: [AppPreviewDocument] = []
        var messages: [String] = []

        let hotLabels = labelGenerationService.makeHotLabels(from: importViewModel.importedOrders)
        if !hotLabels.isEmpty {
            documents.append(
                AppPreviewDocument(
                    title: "Hot Labels Preview",
                    document: labelGenerationService.makePDFDocument(for: hotLabels)
                )
            )
            messages.append("Hot Labels created")
        }

        let coldLabels = labelGenerationService.makeColdLabels(from: importViewModel.importedOrders)
        if !coldLabels.isEmpty {
            documents.append(
                AppPreviewDocument(
                    title: "Cold Labels Preview",
                    document: labelGenerationService.makePDFDocument(for: coldLabels)
                )
            )
            messages.append("Cold Labels created")
        }

        let productionReports = kitchenProductionListService.makeReports(from: importViewModel.importedOrders)
        documents.append(contentsOf: productionReports.map { report in
            AppPreviewDocument(title: "Kitchen Production List - \(report.schoolName)", document: report.document)
        })
        if !productionReports.isEmpty {
            messages.append("Kitchen Production List created")
        }

        let classReports = classPackingListService.makeReports(from: importViewModel.importedOrders)
        documents.append(contentsOf: classReports.map { report in
            AppPreviewDocument(title: "Class Packing List - \(report.schoolName)", document: report.document)
        })
        if !classReports.isEmpty {
            messages.append("Class Packing Lists created")
        }

        guard !documents.isEmpty else { return }
        previewDocuments = documents
        messages.append("All reports generated successfully.")
        showStatus(messages)
    }

    private func showStatus(_ messages: [String]) {
        statusMessages = messages
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            isShowingStatusPanel = true
        }
    }
}

private enum AppScreen: String, CaseIterable, Identifiable {
    case dashboard
    case importCSV
    case labels
    case kitchenProduction
    case classPacking
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            "Dashboard"
        case .importCSV:
            "Import CSV"
        case .labels:
            "Labels"
        case .kitchenProduction:
            "Kitchen Production"
        case .classPacking:
            "Class Packing Lists"
        case .settings:
            "Settings"
        case .about:
            "About"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "house"
        case .importCSV:
            "square.and.arrow.down"
        case .labels:
            "tag"
        case .kitchenProduction:
            "fork.knife"
        case .classPacking:
            "shippingbox"
        case .settings:
            "gearshape"
        case .about:
            "info.circle"
        }
    }
}

private struct DashboardHomeView: View {
    @Bindable var viewModel: ImportViewModel
    var selectScreen: (AppScreen) -> Void
    var importCSV: () -> Void
    var generatePack: () -> Void
    var generateHotLabels: () -> Void
    var generateColdLabels: () -> Void
    var generateKitchenProduction: () -> Void
    var generateClassPacking: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                summaryCards
                primaryActions
                quickAccess
                recentActivity
            }
            .padding(32)
            .frame(maxWidth: 1180, alignment: .topLeading)
        }
        .navigationTitle("School Lunch Manager")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("School Lunch Manager")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppTheme.charcoal)
            Text(AppDateFormatter.dashboardDate.string(from: Date()))
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            DashboardSummaryCard(title: "Today's Orders", value: viewModel.totalOrders.formatted(), symbol: "takeoutbag.and.cup.and.straw", tint: AppTheme.primary)
            DashboardSummaryCard(title: "Schools", value: viewModel.totalSchools.formatted(), symbol: "building.2", tint: AppTheme.accent)
            DashboardSummaryCard(title: "Reports Ready", value: reportsReady.formatted(), symbol: "doc.text.magnifyingglass", tint: AppTheme.primary)
            DashboardSummaryCard(title: "Status", value: statusText, symbol: statusSymbol, tint: AppTheme.accent)
        }
    }

    private var primaryActions: some View {
        HStack(spacing: 14) {
            Button(action: importCSV) {
                Label(viewModel.isImporting ? "Importing..." : "Import CSV", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isImporting)

            Button(action: generatePack) {
                Label("Generate Today's Pack", systemImage: "checklist")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.importedOrders.isEmpty)
        }
    }

    private var quickAccess: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.headline)
                .foregroundStyle(AppTheme.charcoal)

            HStack(spacing: 10) {
                QuickAccessButton(title: "Hot Labels", symbol: "flame", action: generateHotLabels)
                    .disabled(viewModel.importedOrders.isEmpty)
                QuickAccessButton(title: "Cold Labels", symbol: "snowflake", action: generateColdLabels)
                    .disabled(viewModel.importedOrders.isEmpty)
                QuickAccessButton(title: "Kitchen Production", symbol: "fork.knife", action: generateKitchenProduction)
                    .disabled(viewModel.importedOrders.isEmpty)
                QuickAccessButton(title: "Class Packing Lists", symbol: "shippingbox", action: generateClassPacking)
                    .disabled(viewModel.importedOrders.isEmpty)
                QuickAccessButton(title: "Settings", symbol: "gearshape") {
                    selectScreen(.settings)
                }
            }
        }
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Imports")
                .font(.headline)
                .foregroundStyle(AppTheme.charcoal)

            if viewModel.recentImports.isEmpty {
                Text("Import a Wix CSV to begin today's lunch workflow.")
                    .foregroundStyle(.secondary)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentImports.prefix(4)) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.filename)
                                    .font(.body.weight(.medium))
                                Text(session.importDate, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(session.totalOrders) orders")
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        Divider()
                    }
                }
                .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var reportsReady: Int {
        viewModel.importedOrders.isEmpty ? 0 : 4
    }

    private var statusText: String {
        viewModel.importedOrders.isEmpty ? "Import needed" : "Ready"
    }

    private var statusSymbol: String {
        viewModel.importedOrders.isEmpty ? "clock" : "checkmark.circle"
    }
}

private struct ImportCSVView: View {
    @Bindable var viewModel: ImportViewModel
    var importCSV: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(title: "Import CSV", subtitle: "Import Wix school lunch CSV exports for today's orders.")

                Button(action: importCSV) {
                    Label(viewModel.isImporting ? "Importing..." : "Choose Wix CSV", systemImage: "square.and.arrow.down")
                        .frame(minWidth: 220)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isImporting)

                HStack(spacing: 14) {
                    DashboardSummaryCard(title: "Orders", value: viewModel.totalOrders.formatted(), symbol: "bag", tint: AppTheme.primary)
                    DashboardSummaryCard(title: "Students", value: viewModel.totalStudents.formatted(), symbol: "person.2", tint: AppTheme.accent)
                    DashboardSummaryCard(title: "Classes", value: viewModel.totalClasses.formatted(), symbol: "rectangle.3.group", tint: AppTheme.primary)
                    DashboardSummaryCard(title: "Schools", value: viewModel.totalSchools.formatted(), symbol: "building.2", tint: AppTheme.accent)
                }

                if !viewModel.issues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Import Warnings")
                            .font(.headline)
                        ForEach(viewModel.issues) { issue in
                            Text("Line \(issue.lineNumber): \(issue.message)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(32)
            .frame(maxWidth: 1080, alignment: .topLeading)
        }
        .navigationTitle("Import CSV")
    }
}

private struct SingleReportView: View {
    var title: String
    var subtitle: String
    var buttonTitle: String
    var systemImage: String
    var orders: [LunchOrder]
    var generatedCount: Int
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(title: title, subtitle: subtitle)

            HStack(spacing: 14) {
                DashboardSummaryCard(title: "Imported Orders", value: orders.count.formatted(), symbol: "bag", tint: AppTheme.primary)
                DashboardSummaryCard(title: "Schools", value: Set(orders.map(\.school.id)).count.formatted(), symbol: "building.2", tint: AppTheme.accent)
                DashboardSummaryCard(title: "Reports", value: generatedCount.formatted(), symbol: "doc.text", tint: AppTheme.primary)
            }

            Button(action: action) {
                Label(buttonTitle, systemImage: systemImage)
                    .frame(minWidth: 260)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(orders.isEmpty)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(title)
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("General") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Build", value: "1")
            }
            Section("Printers") {
                Text("Printer defaults will be configured in a future release.")
                    .foregroundStyle(.secondary)
            }
            Section("Schools") {
                Text("School profiles will be configured in a future release.")
                    .foregroundStyle(.secondary)
            }
            Section("Menu") {
                Text("Menu item rules will be configured in a future release.")
                    .foregroundStyle(.secondary)
            }
            Section("Appearance") {
                Text("Theme options will be configured in a future release.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .navigationTitle("Settings")
    }
}

private struct AboutView: View {
    @State private var didOpenAboutWindow = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(title: "About", subtitle: "Application information and credits.")

            Button {
                AboutWindow.show()
            } label: {
                Label("Open About Window", systemImage: "info.circle")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("About")
        .onAppear {
            guard !didOpenAboutWindow else { return }
            didOpenAboutWindow = true
            AboutWindow.show()
        }
    }
}

private struct DashboardSummaryCard: View {
    var title: String
    var value: String
    var symbol: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.charcoal)
                    .lineLimit(1)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct QuickAccessButton: View {
    var title: String
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.callout.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 78)
        }
        .buttonStyle(.bordered)
    }
}

private struct PageHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(AppTheme.charcoal)
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusPanel: View {
    var messages: [String]
    var dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Reports Ready")
                    .font(.headline)
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            ForEach(messages, id: \.self) { message in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppTheme.accent)
                    Text(message)
                        .font(.callout)
                }
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }
}

private struct AppPreviewDocument: Identifiable {
    let id = UUID()
    var title: String
    var document: PDFDocument
    var isPresented = true
}

private enum AppTheme {
    static let primary = Color.orange
    static let accent = Color.green
    static let appBackground = Color.white
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let charcoal = Color(red: 0.12, green: 0.12, blue: 0.11)
}

private enum AppDateFormatter {
    static let dashboardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter
    }()
}

private enum AboutWindow {
    static func show() {
        let hostingController = NSHostingController(rootView: AboutWindowContent())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About School Lunch Manager"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 420, height: 420))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
    }
}

private struct AboutWindowContent: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 86, height: 86)
                .cornerRadius(18)

            Text("School Lunch Manager")
                .font(.title.bold())
                .foregroundStyle(AppTheme.charcoal)
            Text("Version 1.0")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Build 1")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 6)

            Text("Designed and developed for")
                .foregroundStyle(.secondary)
            Text("Espresso Cafe")
                .font(.title3.bold())
            Text("Burnside, Victoria")
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text("© 2026 Espresso Cafe")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("All Rights Reserved")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 420, height: 420)
        .background(Color.white)
    }
}

#Preview {
    ContentView()
}
