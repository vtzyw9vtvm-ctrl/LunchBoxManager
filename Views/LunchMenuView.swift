import SwiftUI

struct LunchMenuView: View {

    @State private var viewModel = MenuViewModel()

    var body: some View {

        NavigationStack {

            List {

                Section {

                    ForEach(viewModel.categories) { category in

                        NavigationLink {

                            LunchCategoryView(
                                category: category,
                                viewModel: viewModel
                            )

                        } label: {

                            HStack(spacing: 16) {

                                Text(category.icon)
                                    .font(.largeTitle)

                                VStack(alignment: .leading, spacing: 4) {

                                    Text(category.name)
                                        .font(.headline)

                                    Text("\(category.items.count) item\(category.items.count == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)

                            }
                            .padding(.vertical, 6)

                        }

                    }

                } header: {

                    Text("Categories")

                }

            }
            .navigationTitle("Lunch Menu")

        }

    }

}

#Preview {
    LunchMenuView()
}
