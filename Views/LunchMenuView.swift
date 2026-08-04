import SwiftUI

struct LunchMenuView: View {

    private let categories = LunchCategory.defaults

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text("Lunch Menu")
                    .font(.largeTitle.bold())

                Text("Manage the menu that parents see when ordering lunch.")
                    .foregroundStyle(.secondary)

                Divider()

                ForEach(categories) { category in

                    HStack {

                        Text(category.icon)
                            .font(.title)

                        Text(category.name)
                            .font(.title2.weight(.semibold))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)

                    }
                    .padding()

                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )

                }

                Spacer()

            }
            .padding(32)

        }
        .navigationTitle("Lunch Menu")

    }

}

#Preview {
    LunchMenuView()
}
