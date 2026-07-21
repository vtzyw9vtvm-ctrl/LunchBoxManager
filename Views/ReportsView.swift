import PDFKit
import SwiftUI

/// Generates operational PDF reports for kitchen preparation.
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
            "No Reports Generated",
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
            Text(viewModel.message ?? "Import orders before generating kitchen run sheets.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reports")
                .font(.largeTitle.weight(.semibold))
            Text("Generate kitchen run sheets grouped by school for daily preparation.")
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        Button {
            viewModel.generateKitchenRunSheets(from: orders)
            previewReports = viewModel.reports.map { report in
                ReportPreviewState(
                    title: "Kitchen Run Sheet - \(report.schoolName)",
                    document: report.document
                )
            }
        } label: {
            Label("Generate Kitchen Run Sheets", systemImage: "doc.text")
        }
        .buttonStyle(.borderedProminent)
        .disabled(orders.isEmpty)
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
