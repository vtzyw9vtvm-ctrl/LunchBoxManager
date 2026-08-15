import SwiftUI

struct ClassListView: View {

    @Bindable var manager: ClassesViewModel
    @Bindable var studentsManager: StudentsViewModel

    @Binding var selectedSchool: School
    @Binding var selectedClass: SchoolClass?

    private var classes: [SchoolClass] {

        manager.classes
            .filter { $0.schoolID == selectedSchool.id }
            .sorted { $0.name < $1.name }

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Classes")
                    .font(.title2.bold())

                Spacer()

                // Delete selected class
                Button {

                    guard let selectedClass else {
                        return
                    }

                    manager.deleteClass(selectedClass)

                    self.selectedClass = nil

                } label: {

                    Image(systemName: "trash")

                }
                .buttonStyle(.borderless)
                .disabled(selectedClass == nil)
                .help("Delete Selected Class")

                // Add new class
                Button {

                    let newClass = SchoolClass(
                        name: "New Class",
                        schoolID: selectedSchool.id
                    )

                    manager.classes.append(newClass)
                    manager.updateClass(newClass)

                    selectedClass = newClass

                } label: {

                    Label("Add Class", systemImage: "plus")

                }

            }

            Divider()

            if classes.isEmpty {

                ContentUnavailableView(
                    "No Classes",
                    systemImage: "graduationcap"
                )

            } else {

                List(
                    classes,
                    selection: $selectedClass
                ) { schoolClass in

                    ClassRowView(
                        schoolClass: schoolClass,
                        studentCount: studentsManager.students.filter {
                            $0.classID == schoolClass.id
                        }.count,
                        isSelected: selectedClass?.id == schoolClass.id
                    )
                    .tag(schoolClass)

                }

            }

        }
        .padding()

    }

}
