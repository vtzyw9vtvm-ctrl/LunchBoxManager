import SwiftUI

struct StudentListView: View {

    @Bindable var manager: StudentsViewModel

    let selectedClass: SchoolClass

    @Binding var selectedStudent: Student?

    private var classStudents: [Student] {
        manager.students
            .filter { $0.classID == selectedClass.id }
            .sorted {
                $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
            }
    }

    var body: some View {

        VStack(spacing: 0) {

            HStack {

                VStack(alignment: .leading, spacing: 2) {

                    Text("Students")
                        .font(.headline)

                    Text(selectedClass.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                }

                Spacer()

                Button {

                    var student = manager.addStudent()

                    student.classID = selectedClass.id
                    manager.updateStudent(student)

                    selectedStudent = student

                } label: {

                    Image(systemName: "plus")

                }
                .buttonStyle(.borderless)
                .help("Add Student")

            }
            .padding()

            Divider()

            if classStudents.isEmpty {

                ContentUnavailableView(
                    "No Students",
                    systemImage: "person.2",
                    description: Text("Students in \(selectedClass.name) will appear here.")
                )

            } else {

                List(
                    classStudents,
                    selection: $selectedStudent
                ) { student in

                    HStack {

                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)

                        Text(student.fullName)

                        Spacer()

                        if !student.isActive {

                            Text("Inactive")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                        }

                    }
                    .tag(student)

                }

            }

        }

    }

}
