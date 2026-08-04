import PDFKit
import SwiftUI

/// Generates operational PDF reports for kitchen production.
struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var previewReports: [ReportPreviewState] = []
    var orders: [LunchOrder]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            actions
            reportSummary
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Reports")
        .background {
            ForEach(previewReports.indices, id: \.self) { index in
                LabelsPreviewWindowPresenter(
                    isPresented: Binding(
                        get: { previewReports.indices.contains(index) && previewReports[index].isPresented },
                        set: { isPresented in
                            guard previewReports.indices.contains(index) else { return }
                            previewReports[index].isPresented = isPresented
                        }
                    ),
                    title: previewReports[index].title,
                    document: previewReports[index].document
                )
                .frame(width: 0, height: 0)
            }
        }
        .alert(
            viewModel.messageTitle,
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
            Text(viewModel.message ?? "Import orders before generating kitchen production lists.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reports")
                .font(.largeTitle.weight(.semibold))
            Text("Generate kitchen production, pasta preparation and class packing reports.")
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                viewModel.generateKitchenProductionLists(from: orders)
                previewReports = viewModel.productionListReports.map { report in
                    ReportPreviewState(
                        title: "\(report.schoolName) Kitchen Production.pdf",
                        document: report.document
                    )
                } + viewModel.pastaPreparationReports.map { report in
                    ReportPreviewState(
                        title: "\(report.reportName).pdf",
                        document: report.document
                    )
                }
            } label: {
                Label("Generate Kitchen Production Lists", systemImage: "doc.text")
            }
            .buttonStyle(.borderedProminent)
            .disabled(orders.isEmpty)

            Button {
                viewModel.generateClassPackingLists(from: orders)
                previewReports = viewModel.classPackingListReports.map { report in
                    ReportPreviewState(
                        title: "Class Packing List - \(report.schoolName)",
                        document: report.document
                    )
                }
            } label: {
                Label("Generate Class Packing Lists", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .disabled(orders.isEmpty)
        }
    }

    private var reportSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Imported Wix Orders", value: orders.count.formatted())
            LabeledContent("Schools Ready", value: schoolCount.formatted())
            LabeledContent("Generated Reports", value: viewModel.reportCount.formatted())
        }
        .frame(maxWidth: 360, alignment: .leading)
    }

    private var schoolCount: Int {
        Set(orders.map(\.school.id)).count
    }
}

private struct ReportPreviewState: Identifiable {
    let id = UUID()
    var title: String
    var document: PDFDocument
    var isPresented = true
}

#Preview {
    ReportsView(orders: SampleDataService().makeSampleImport().orders)
}
