import SwiftUI

struct CategoryInspector: View {

    @Binding var category: LunchCategory

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(category.name.isEmpty ? "New Category" : category.name)
                    .font(.largeTitle.bold())

                Divider()

                SectionCard("Category") {

                    TextField("Category Name", text: $category.name)
                        .textFieldStyle(.roundedBorder)

                    HStack {

                        Text("Icon")

                        Spacer()

                        TextField("", text: $category.icon)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)

                    }

                }

                SectionCard("Statistics") {

                    HStack {

                        Text("Menu Items")

                        Spacer()

                        Text("\(category.items.count)")
                            .font(.headline)

                    }

                }

            }
            .padding(24)

        }

    }

}

#Preview {

    @Previewable
    @State var category = LunchCategory(
        name: "Hot Food",
        icon: "🍔"
    )

    CategoryInspector(category: $category)

}
