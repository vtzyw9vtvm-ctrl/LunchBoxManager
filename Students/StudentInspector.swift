import SwiftUI

struct StudentInspector: View {

    @Binding var student: Student

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(student.fullName)
                    .font(.largeTitle.bold())

                Divider()

                SectionCard("Student") {

                    HStack {

                        Text("First Name")
                            .frame(width: 100, alignment: .leading)

                        TextField("", text: $student.firstName)
                            .textFieldStyle(.roundedBorder)

                    }

                    HStack {

                        Text("Last Name")
                            .frame(width: 100, alignment: .leading)

                        TextField("", text: $student.lastName)
                            .textFieldStyle(.roundedBorder)

                    }

                    HStack {

                        Text("Class")
                            .frame(width: 100, alignment: .leading)

                        Text(student.classID == nil ? "Not Assigned" : "Assigned")
                            .foregroundStyle(.secondary)

                    }

                }

                SectionCard("Information") {

                    TextField("Allergies", text: $student.allergies)
                        .textFieldStyle(.roundedBorder)

                    TextField(
                        "Notes",
                        text: $student.notes,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                    Toggle("Active", isOn: $student.isActive)

                }

            }
            .padding(24)

        }

    }

}

#Preview {

    @Previewable
    @State var student = Student(
        firstName: "Ava",
        lastName: "Nguyen"
    )

    StudentInspector(student: $student)

}
