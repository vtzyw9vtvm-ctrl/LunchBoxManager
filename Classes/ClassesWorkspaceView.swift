import SwiftUI

struct ClassesWorkspaceView: View {

    @State private var classManager = ClassesViewModel()

    @State private var selectedClass: SchoolClass?

    @State private var searchText = ""

    private var filteredClasses: [SchoolClass] {

        if searchText.isEmpty {
            return classManager.classes
        }

        return classManager.classes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }

    }

    var body: some View {

        HSplitView {

            VStack(spacing: 0) {

                ToolbarView(
                    title: "Classes",
                    systemImage: "plus"
                ) {

                    let newClass = classManager.addClass()

                    selectedClass = newClass

                }

                Divider()

                SearchBar(
                    placeholder: "Search classes...",
                    text: $searchText
                )
                .padding()

                List(filteredClasses, selection: $selectedClass) { schoolClass in

                    ClassRowView(
                        schoolClass: schoolClass,
                        isSelected: selectedClass?.id == schoolClass.id
                    )
                    .tag(schoolClass)

                }

            }
            .frame(minWidth: 300)

            Group {

                if
                    let selectedClass,
                    let index = classManager.classes.firstIndex(where: { $0.id == selectedClass.id })
                {

                    ClassInspector(

                        schoolClass: Binding(

                            get: {

                                classManager.classes[index]

                            },

                            set: {

                                classManager.updateClass($0)

                            }

                        )

                    )

                } else {

                    ContentUnavailableView(
                        "Select a Class",
                        systemImage: "graduationcap"
                    )

                }

            }
            .frame(width: 420)

        }

    }

}

#Preview {

    ClassesWorkspaceView()

}
