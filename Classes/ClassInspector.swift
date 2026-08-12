import SwiftUI

struct ClassInspector: View {

    @Binding var schoolClass: SchoolClass

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(schoolClass.name)
                    .font(.largeTitle.bold())

                Divider()

                SectionCard("Class") {

                    HStack {

                        Text("Class")
                            .frame(width: 110, alignment: .leading)

                        TextField("", text: $schoolClass.name)
                            .textFieldStyle(.roundedBorder)

                    }

                    

                }

                SectionCard("Status") {

                    Toggle("Active", isOn: $schoolClass.isActive)

                }

            }
            .padding(24)

        }

    }

}

#Preview {

    @Previewable
    @State var schoolClass = SchoolClass(
        name: "3A",
        schoolID: UUID()
    )

    ClassInspector(schoolClass: $schoolClass)

}
