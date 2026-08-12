import SwiftUI

struct StudentsWorkspaceView: View {

    @State private var studentsManager = StudentsViewModel()

    @State private var selectedStudent: Student?

    @State private var searchText = ""

    var filteredStudents: [Student] {

        studentsManager.students.filter {

            searchText.isEmpty ||

            $0.fullName.localizedCaseInsensitiveContains(searchText)

        }

    }

    var body: some View {

        HSplitView {

            VStack(spacing: 0) {

                toolbar(
                    title: "Students",
                    systemImage: "plus"
                ) {

                    let student = studentsManager.addStudent()

                    selectedStudent = student

                }

                Divider()

                TextField("Search Students...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                List(
                    filteredStudents,
                    selection: $selectedStudent
                ) {

                    student in

                    StudentRowView(
                        student: student,
                        isSelected: selectedStudent?.id == student.id
                    )
                    .tag(student)

                }

            }
            .frame(minWidth: 300)

            Group {

                if
                    let student = selectedStudent,
                    let index = studentsManager.students.firstIndex(where: { $0.id == student.id })
                {

                    StudentInspector(

                        student: Binding(

                            get: {

                                studentsManager.students[index]

                            },

                            set: {

                                studentsManager.updateStudent($0)

                            }

                        )

                    )

                }

                else {

                    ContentUnavailableView(
                        "Select Student",
                        systemImage: "person"
                    )

                }

            }
            .frame(width: 420)

        }

    }

    @ViewBuilder
    private func toolbar(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        HStack {

            Text(title)
                .font(.headline)

            Spacer()

            Button(action: action) {

                Image(systemName: systemImage)

            }

            .buttonStyle(.borderless)

        }

        .padding()

    }

}

#Preview {

    StudentsWorkspaceView()

}
