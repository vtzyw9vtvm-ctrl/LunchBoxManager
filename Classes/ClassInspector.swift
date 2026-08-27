import SwiftUI

struct ClassInspector: View {

    @Binding var schoolClass: SchoolClass

    private let yearLevels = [
        "Prep",
        "Grade 1",
        "Grade 2",
        "Grade 3",
        "Grade 4",
        "Grade 5",
        "Grade 6",
        "Grade 5/6",
        "Staff"
    ]

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(schoolClass.name)
                    .font(.largeTitle.bold())

                Divider()


                // MARK: - Class

                SectionCard("Class") {

                    HStack {

                        Text("Class")
                            .frame(
                                width: 110,
                                alignment: .leading
                            )

                        TextField(
                            "",
                            text: $schoolClass.name
                        )
                        .textFieldStyle(.roundedBorder)
                    }


                    HStack {

                        Text("Year Level")
                            .frame(
                                width: 110,
                                alignment: .leading
                            )

                        Picker(
                            "",
                            selection: $schoolClass.yearLevel
                        ) {

                            Text("Select Year Level")
                                .tag("")

                            ForEach(
                                yearLevels,
                                id: \.self
                            ) { yearLevel in

                                Text(yearLevel)
                                    .tag(yearLevel)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                }


                // MARK: - Lunch Days

                SectionCard("Lunch Days") {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Text(
                            "School lunches are available "
                            + "for this class on:"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        HStack(spacing: 8) {

                            ForEach(
                                SchoolLunchDay.allCases,
                                id: \.self
                            ) { day in

                                Button {

                                    toggleLunchDay(day)

                                } label: {

                                    Text(day.shortTitle)
                                        .frame(
                                            maxWidth: .infinity
                                        )
                                }
                                .buttonStyle(.bordered)
                                .tint(
                                    schoolClass
                                        .lunchDays
                                        .contains(day)
                                        ? .accentColor
                                        : .gray
                                )
                            }
                        }
                    }
                }


                // MARK: - Status

                SectionCard("Status") {

                    Toggle(
                        "Active",
                        isOn: $schoolClass.isActive
                    )
                }
            }
            .padding(24)
        }
    }


    // MARK: - Lunch Days

    private func toggleLunchDay(
        _ day: SchoolLunchDay
    ) {

        // Use a copy so the outer Binding setter
        // receives the updated SchoolClass.
        var updatedClass = schoolClass

        if updatedClass.lunchDays.contains(day) {

            updatedClass.lunchDays.remove(day)

        } else {

            updatedClass.lunchDays.insert(day)
        }

        schoolClass = updatedClass
    }
}


#Preview {

    @Previewable
    @State var schoolClass = SchoolClass(
        name: "3A",
        yearLevel: "Grade 3",
        schoolID: UUID()
    )

    ClassInspector(
        schoolClass: $schoolClass
    )
}
