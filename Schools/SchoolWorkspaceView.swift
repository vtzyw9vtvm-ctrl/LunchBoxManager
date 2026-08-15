import SwiftUI

struct SchoolsWorkspaceView: View {

    @State private var schoolsManager = SchoolsViewModel()
    @State private var classesManager = ClassesViewModel()
    @State private var studentsManager = StudentsViewModel()

    @State private var selectedSchool: School?
    @State private var selectedClass: SchoolClass?

    @State private var searchText = ""

    var filteredSchools: [School] {

        schoolsManager.schools.filter {

            searchText.isEmpty ||

            $0.name.localizedCaseInsensitiveContains(searchText) ||

            $0.shortName.localizedCaseInsensitiveContains(searchText)

        }

    }

    var body: some View {

        HSplitView {

            // MARK: - Schools

            VStack(spacing: 0) {

                toolbar(
                    title: "Schools",
                    systemImage: "plus"
                ) {

                    let school = schoolsManager.addSchool()
                    selectedSchool = school
                    selectedClass = nil

                }

                Divider()

                TextField(
                    "Search Schools...",
                    text: $searchText
                )
                .textFieldStyle(.roundedBorder)
                .padding()

                List(
                    filteredSchools,
                    selection: $selectedSchool
                ) { school in

                    SchoolRowView(
                        school: school,
                        isSelected: selectedSchool?.id == school.id
                    )
                    .tag(school)

                }

            }
            .frame(
                minWidth: 300,
                maxHeight: .infinity,
                alignment: .top
            )

            // MARK: - School Setup

            Group {

                if
                    let school = selectedSchool,
                    let index = schoolsManager.schools.firstIndex(
                        where: { $0.id == school.id }
                    )
                {

                    VStack(spacing: 0) {

                        SchoolInspector(
                            school: Binding(
                                get: {
                                    schoolsManager.schools[index]
                                },
                                set: {
                                    schoolsManager.updateSchool($0)
                                }
                            )
                        )

                        Divider()

                        ClassListView(
                            manager: classesManager,
                            studentsManager: studentsManager,
                            selectedSchool: Binding(
                                get: {
                                    schoolsManager.schools[index]
                                },
                                set: {
                                    schoolsManager.updateSchool($0)
                                }
                            ),
                            selectedClass: $selectedClass
                        )

                        if
                            let selectedClass,
                            let classIndex = classesManager.classes.firstIndex(
                                where: { $0.id == selectedClass.id }
                            )
                        {

                            Divider()

                            ClassInspector(
                                schoolClass: Binding(
                                    get: {
                                        classesManager.classes[classIndex]
                                    },
                                    set: {
                                        classesManager.updateClass($0)
                                    }
                                )
                            )

                        }

                    }

                    } else {
                    ContentUnavailableView(
                        "Select School",
                        systemImage: "building.2"
                    )

                }

            }
            .frame(width: 420)

        }
        .onAppear {

            if selectedSchool == nil {
                selectedSchool = schoolsManager.schools.first
            }

        }
        .onChange(of: selectedSchool) {

            // Don't leave a class from the previous school selected.
            selectedClass = nil

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

    SchoolsWorkspaceView()

}
