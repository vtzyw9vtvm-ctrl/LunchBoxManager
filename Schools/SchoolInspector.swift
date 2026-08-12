import SwiftUI

struct SchoolInspector: View {

    @Binding var school: School

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(school.name)
                    .font(.largeTitle.bold())

                Divider()

                SectionCard("School") {

                    HStack {

                        Text("School Name")
                            .frame(width: 110, alignment: .leading)

                        TextField("", text: $school.name)
                            .textFieldStyle(.roundedBorder)

                    }

                    HStack {

                        Text("Short Name")
                            .frame(width: 110, alignment: .leading)

                        TextField("", text: $school.shortName)
                            .textFieldStyle(.roundedBorder)

                    }

                }

                SectionCard("Delivery") {

                    HStack {

                        Text("Cut-off")
                            .frame(width: 110, alignment: .leading)

                        TextField("", text: $school.orderCutoffTime)
                            .textFieldStyle(.roundedBorder)

                    }

                    HStack {

                        Text("Delivery")
                            .frame(width: 110, alignment: .leading)

                        TextField("", text: $school.deliveryTime)
                            .textFieldStyle(.roundedBorder)

                    }

                }

                SectionCard("Notes") {

                    TextField(
                        "Notes",
                        text: $school.notes,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)

                    Toggle("Active", isOn: $school.isActive)

                }

            }
            .padding(24)

        }

    }

}

#Preview {

    @Previewable
    @State var school = School(
        name: "Burnside Primary School",
        shortName: "BPS"
    )

    SchoolInspector(school: $school)

}
