import SwiftUI

struct SchoolsWorkspaceView: View {

    @State private var schoolsManager = SchoolsViewModel()

    @State private var selectedSchool: School?

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

            VStack(spacing: 0) {

                toolbar(
                    title: "Schools",
                    systemImage: "plus"
                ) {

                    let school = schoolsManager.addSchool()

                    selectedSchool = school

                }

                Divider()

                TextField("Search Schools...", text: $searchText)
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
            .frame(minWidth: 300)

            Group {

                if
                    let school = selectedSchool,
                    let index = schoolsManager.schools.firstIndex(where: { $0.id == school.id })
                {

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

                }

                else {

                    ContentUnavailableView(
                        "Select School",
                        systemImage: "building.2"
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

    SchoolsWorkspaceView()

}
