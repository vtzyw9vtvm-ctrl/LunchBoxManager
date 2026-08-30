import SwiftUI

struct PageBannerView: View {

    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(title.uppercased())
                    .font(
                        .system(
                            size: 38,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(0.78)
                    )
            }

            Spacer()

            Image(systemName: systemImage)
                .font(
                    .system(
                        size: 38,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 17)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(color)
    }
}


// MARK: - LunchBox Page Colours

extension Color {

    static let lunchBoxNavy = Color(
        red: 0.114,
        green: 0.169,
        blue: 0.271
    )

    static let lunchBoxGreen = Color(
        red: 0.333,
        green: 0.478,
        blue: 0.353
    )

    static let lunchBoxPurple = Color(
        red: 0.459,
        green: 0.380,
        blue: 0.604
    )

    static let lunchBoxBlue = Color(
        red: 0.333,
        green: 0.467,
        blue: 0.612
    )

    static let lunchBoxOrangeBrown = Color(
        red: 0.714,
        green: 0.435,
        blue: 0.239
    )

    static let lunchBoxTeal = Color(
        red: 0.310,
        green: 0.486,
        blue: 0.478
    )
}


#Preview {

    PageBannerView(
        title: "Menu",
        subtitle: "Manage menu items, categories and pricing",
        systemImage: "fork.knife",
        color: .lunchBoxGreen
    )
}
