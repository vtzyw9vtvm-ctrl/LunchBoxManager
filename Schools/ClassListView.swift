import SwiftUI

struct ClassListView: View {

    @Bindable var manager: ClassesViewModel
    @Bindable var studentsManager: StudentsViewModel

    @Binding var selectedSchool: School
    @Binding var selectedClass: SchoolClass?

    private var classes: [SchoolClass] {

        manager.classes
            .filter { $0.schoolID == selectedSchool.id }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }

                return $0.sortOrder < $1.sortOrder
            }
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Classes")
                    .font(.title2.bold())

                Spacer()

                // Move selected class up
                Button {

                    moveSelectedClassUp()

                } label: {

                    Image(systemName: "arrow.up")

                }
                .buttonStyle(.borderless)
                .disabled(!canMoveSelectedClassUp)
                .help("Move Class Up")

                // Move selected class down
                Button {

                    moveSelectedClassDown()

                } label: {

                    Image(systemName: "arrow.down")

                }
                .buttonStyle(.borderless)
                .disabled(!canMoveSelectedClassDown)
                .help("Move Class Down")

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
                        schoolID: selectedSchool.id,
                        sortOrder: classes.count
                    )

                    manager.classes.append(newClass)

                    normaliseClassOrder()

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
        .onAppear {

            initialiseClassOrderIfNeeded()

        }
    }


    // MARK: - Move Availability

    private var canMoveSelectedClassUp: Bool {

        guard
            let selectedClass,
            let index = classes.firstIndex(
                where: { $0.id == selectedClass.id }
            )
        else {
            return false
        }

        return index > 0
    }

    private var canMoveSelectedClassDown: Bool {

        guard
            let selectedClass,
            let index = classes.firstIndex(
                where: { $0.id == selectedClass.id }
            )
        else {
            return false
        }

        return index < classes.count - 1
    }


    // MARK: - Reordering

    private func moveSelectedClassUp() {

        guard
            let selectedClass,
            let index = classes.firstIndex(
                where: { $0.id == selectedClass.id }
            ),
            index > 0
        else {
            return
        }

        moveClass(
            selectedClass,
            to: index - 1
        )
    }

    private func moveSelectedClassDown() {

        guard
            let selectedClass,
            let index = classes.firstIndex(
                where: { $0.id == selectedClass.id }
            ),
            index < classes.count - 1
        else {
            return
        }

        moveClass(
            selectedClass,
            to: index + 1
        )
    }

    private func moveClass(
        _ schoolClass: SchoolClass,
        to destinationIndex: Int
    ) {

        var orderedClasses = classes

        guard
            let sourceIndex = orderedClasses.firstIndex(
                where: { $0.id == schoolClass.id }
            )
        else {
            return
        }

        let movedClass = orderedClasses.remove(
            at: sourceIndex
        )

        orderedClasses.insert(
            movedClass,
            at: destinationIndex
        )

        saveOrder(orderedClasses)
    }

    private func saveOrder(
        _ orderedClasses: [SchoolClass]
    ) {

        for (index, schoolClass) in orderedClasses.enumerated() {

            var updatedClass = schoolClass
            updatedClass.sortOrder = index

            manager.updateClass(updatedClass)

        }
    }


    // MARK: - Initial Ordering

    private func initialiseClassOrderIfNeeded() {

        let schoolClasses = classes

        guard schoolClasses.count > 1 else {
            return
        }

        // Older saved classes all have sortOrder = 0.
        // Give them a stable initial order.
        let needsInitialOrder =
            Set(schoolClasses.map(\.sortOrder)).count != schoolClasses.count

        if needsInitialOrder {

            let alphabetical = schoolClasses.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }

            saveOrder(alphabetical)
        }
    }

    private func normaliseClassOrder() {

        saveOrder(classes)
    }
}
