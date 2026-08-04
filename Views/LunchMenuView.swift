import SwiftUI

struct LunchMenuView: View {

    @State private var viewModel = MenuViewModel()

    var body: some View {

        NavigationStack {

            List(viewModel.categories) { category in

                NavigationLink {

                    LunchCategoryView(
                        category: category,
                        viewModel: viewModel
                    )

                } label: {

                    HStack {

                        Text(category.icon)
                            .font(.title2)

                        Text(category.name)
                            .font(.title3.weight(.semibold))

                    }
                    .padding(.vertical, 6)
                }

            }
            .navigationTitle("Lunch Menu")

        }

    }
}

#Preview {
    LunchMenuView()
}
