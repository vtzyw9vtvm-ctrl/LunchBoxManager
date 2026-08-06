import SwiftUI

struct PriceEditor: View {

    @Binding var sellPrice: String
    @Binding var costPrice: String
    @Binding var gstIncluded: Bool

    private var profit: Double {

        (Double(sellPrice) ?? 0) - (Double(costPrice) ?? 0)

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("Pricing")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {

                GridRow {

                    Text("Sell Price")

                    TextField(
                        "0.00",
                        text: $sellPrice
                    )
                    .textFieldStyle(.roundedBorder)

                }

                GridRow {

                    Text("Cost Price")

                    TextField(
                        "0.00",
                        text: $costPrice
                    )
                    .textFieldStyle(.roundedBorder)

                }

                GridRow {

                    Text("Profit")

                    Text("$\(profit, specifier: "%.2f")")
                        .foregroundStyle(.green)
                        .bold()

                }

            }

            Toggle(
                "GST Included",
                isOn: $gstIncluded
            )

        }

    }

}

#Preview {

    @Previewable @State var sell = "12.50"
    @Previewable @State var cost = "4.20"
    @Previewable @State var gst = true

    PriceEditor(
        sellPrice: $sell,
        costPrice: $cost,
        gstIncluded: $gst
    )

}
