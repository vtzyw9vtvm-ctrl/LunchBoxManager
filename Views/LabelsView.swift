import AppKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

/// Generates and previews thermal labels for imported student lunches.
struct LabelsView: View {
    @State private var viewModel: LabelsViewModel
    private let orders: [LunchOrder]

    init(orders: [LunchOrder]) {
        self.orders = orders
        _viewModel = State(initialValue: LabelsViewModel(orders: orders))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            actions
            labelSummary
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Labels")
        .onChange(of: orders) { _, newOrders in
            viewModel.updateOrders(newOrders)
        }
        .background {
            LabelsPreviewWindowPresenter(
                isPresented: Binding(
                    get: { viewModel.isShowingPreview },
                    set: { viewModel.isShowingPreview = $0 }
                ),
                title: viewModel.previewTitle,
                document: viewModel.previewDocument
            )
            .frame(width: 0, height: 0)
        }
        .alert(
            "No Hot Labels",
            isPresented: Binding(
                get: { viewModel.message != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissMessage()
                    }
                }
            )
        ) {
            Button("OK") {
                viewModel.dismissMessage()
            }
        } message: {
            Text(viewModel.message ?? "No labels were generated.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Labels")
                .font(.largeTitle.weight(.semibold))
            Text("Preview hot lunch labels for imported student lunches before printing.")
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.generateHotLabels()
            } label: {
                Label("Generate Hot Labels", systemImage: "flame")
            }
            .buttonStyle(.borderedProminent)
            .disabled(orders.isEmpty)

            Button {
                viewModel.generateColdLabels()
            } label: {
                Label("Generate Cold Labels", systemImage: "snowflake")
            }
            .buttonStyle(.bordered)
            .disabled(orders.isEmpty)
        }
    }

    private var labelSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Imported Wix Orders", value: orders.count.formatted())
            LabeledContent("Student Lunches", value: studentLunchCount.formatted())
            LabeledContent("Hot Labels Ready", value: viewModel.hotLabelCount.formatted())
            LabeledContent("Cold Labels Ready", value: viewModel.coldLabelCount.formatted())
        }
        .frame(maxWidth: 360, alignment: .leading)
    }

    private var studentLunchCount: Int {
        orders.reduce(0) { $0 + $1.studentOrders.count }
    }
}

private struct LabelsPreviewWindowPresenter: NSViewRepresentable {
    @Binding var isPresented: Bool
    var title: String
    var document: PDFDocument?

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.update(title: title, document: document)

        if isPresented {
            context.coordinator.showPreview()
        } else {
            context.coordinator.closePreview()
        }
    }

    final class Coordinator {
        @Binding private var isPresented: Bool
        private var title = "Labels Preview"
        private var document: PDFDocument?
        private var windowController: LabelsPDFWindowController?

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func update(title: String, document: PDFDocument?) {
            self.title = title
            self.document = document
            windowController?.update(title: title, document: document)
        }

        func showPreview() {
            guard let document else { return }

            if windowController == nil {
                windowController = LabelsPDFWindowController(
                    title: title,
                    document: document,
                    onClose: { [weak self] in
                        self?.isPresented = false
                        self?.windowController = nil
                    }
                )
            } else {
                windowController?.update(title: title, document: document)
            }

            windowController?.showWindow(nil)
            windowController?.window?.makeKeyAndOrderFront(nil)
        }

        func closePreview() {
            windowController?.close()
            windowController = nil
        }
    }
}

private final class LabelsPDFWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate {
    private enum ToolbarID {
        static let toolbar = NSToolbar.Identifier("LabelsPDFPreviewToolbar")
        static let close = NSToolbarItem.Identifier("LabelsPDFPreviewClose")
        static let save = NSToolbarItem.Identifier("LabelsPDFPreviewSave")
        static let print = NSToolbarItem.Identifier("LabelsPDFPreviewPrint")
        static let zoomIn = NSToolbarItem.Identifier("LabelsPDFPreviewZoomIn")
        static let zoomOut = NSToolbarItem.Identifier("LabelsPDFPreviewZoomOut")
        static let actualSize = NSToolbarItem.Identifier("LabelsPDFPreviewActualSize")
        static let fitWidth = NSToolbarItem.Identifier("LabelsPDFPreviewFitWidth")
    }

    private let pdfViewController: LabelsPDFViewController
    private let onClose: () -> Void

    init(title: String, document: PDFDocument, onClose: @escaping () -> Void) {
        self.pdfViewController = LabelsPDFViewController(document: document)
        self.onClose = onClose

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentViewController = pdfViewController
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self
        window.toolbar = makeToolbar()
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(title: String, document: PDFDocument?) {
        window?.title = title
        if let document {
            pdfViewController.update(document: document)
        }
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }

    private func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: ToolbarID.toolbar)
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        return toolbar
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            ToolbarID.close,
            ToolbarID.save,
            ToolbarID.print,
            .separator,
            ToolbarID.zoomIn,
            ToolbarID.zoomOut,
            ToolbarID.actualSize,
            ToolbarID.fitWidth,
            .flexibleSpace
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            ToolbarID.close,
            ToolbarID.save,
            ToolbarID.print,
            .separator,
            ToolbarID.zoomIn,
            ToolbarID.zoomOut,
            ToolbarID.actualSize,
            ToolbarID.fitWidth,
            .flexibleSpace
        ]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)

        switch itemIdentifier {
        case ToolbarID.close:
            configure(item, label: "Close", symbol: "xmark", action: #selector(closePreview(_:)))
        case ToolbarID.save:
            configure(item, label: "Save PDF", symbol: "square.and.arrow.down", action: #selector(savePDF(_:)))
        case ToolbarID.print:
            configure(item, label: "Print", symbol: "printer", action: #selector(printPDF(_:)))
        case ToolbarID.zoomIn:
            configure(item, label: "Zoom In", symbol: "plus.magnifyingglass", action: #selector(zoomIn(_:)))
        case ToolbarID.zoomOut:
            configure(item, label: "Zoom Out", symbol: "minus.magnifyingglass", action: #selector(zoomOut(_:)))
        case ToolbarID.actualSize:
            configure(item, label: "Actual Size", symbol: "1.magnifyingglass", action: #selector(actualSize(_:)))
        case ToolbarID.fitWidth:
            configure(item, label: "Fit Width", symbol: "arrow.left.and.right", action: #selector(fitWidth(_:)))
        default:
            return nil
        }

        return item
    }

    private func configure(_ item: NSToolbarItem, label: String, symbol: String, action: Selector) {
        item.label = label
        item.paletteLabel = label
        item.toolTip = label
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        item.target = self
        item.action = action
    }

    @objc private func closePreview(_ sender: Any?) {
        close()
    }

    @objc private func savePDF(_ sender: Any?) {
        guard let document = pdfViewController.document else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(window?.title.replacingOccurrences(of: " ", with: "-") ?? "Labels-Preview").pdf"
        panel.title = "Save Labels PDF"
        panel.prompt = "Save"

        guard let window else { return }
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            document.write(to: url)
        }
    }

    @objc private func printPDF(_ sender: Any?) {
        guard let document = pdfViewController.document else { return }

        let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo()
        printInfo.paperSize = LabelGenerationService.labelSize
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false

        guard let operation = document.printOperation(
            for: printInfo,
            scalingMode: .pageScaleNone,
            autoRotate: false
        ) else { return }

        operation.showsPrintPanel = true
        operation.showsProgressPanel = true

        if let window {
            operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            operation.run()
        }
    }

    @objc private func zoomIn(_ sender: Any?) {
        pdfViewController.zoomIn()
    }

    @objc private func zoomOut(_ sender: Any?) {
        pdfViewController.zoomOut()
    }

    @objc private func actualSize(_ sender: Any?) {
        pdfViewController.actualSize()
    }

    @objc private func fitWidth(_ sender: Any?) {
        pdfViewController.fitWidth()
    }
}

private final class LabelsPDFViewController: NSViewController {
    private let pdfView = PDFView()
    private let thumbnailView = PDFThumbnailView()

    var document: PDFDocument? {
        pdfView.document
    }

    init(document: PDFDocument) {
        super.init(nibName: nil, bundle: nil)
        pdfView.document = document
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin

        let thumbnailScrollView = NSScrollView()
        thumbnailScrollView.hasVerticalScroller = true
        thumbnailScrollView.borderType = .noBorder
        thumbnailScrollView.documentView = thumbnailView

        thumbnailView.pdfView = pdfView
        thumbnailView.maximumNumberOfColumns = 1

        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = .windowBackgroundColor
        pdfView.minScaleFactor = 0.1
        pdfView.maxScaleFactor = 5.0

        splitView.addArrangedSubview(thumbnailScrollView)
        splitView.addArrangedSubview(pdfView)
        thumbnailScrollView.widthAnchor.constraint(equalToConstant: 120).isActive = true

        view = splitView
    }

    func update(document: PDFDocument) {
        if pdfView.document !== document {
            pdfView.document = document
            thumbnailView.pdfView = pdfView
            pdfView.autoScales = true
        }
    }

    func zoomIn() {
        pdfView.autoScales = false
        pdfView.zoomIn(nil)
    }

    func zoomOut() {
        pdfView.autoScales = false
        pdfView.zoomOut(nil)
    }

    func actualSize() {
        pdfView.autoScales = false
        pdfView.scaleFactor = 1
    }

    func fitWidth() {
        guard let page = pdfView.currentPage ?? pdfView.document?.page(at: 0) else { return }

        let pageWidth = page.bounds(for: pdfView.displayBox).width
        guard pageWidth > 0 else { return }

        let availableWidth = max(pdfView.bounds.width - 32, 1)
        let scale = availableWidth / pageWidth
        pdfView.autoScales = false
        pdfView.scaleFactor = min(max(scale, pdfView.minScaleFactor), pdfView.maxScaleFactor)
    }
}

#Preview {
    LabelsView(orders: SampleDataService().makeSampleImport().orders)
}
