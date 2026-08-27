import SwiftUI

struct SchoolInspector: View {

    @Binding var school: School

    private let yearLevels = [
        "Prep",
        "Grade 1",
        "Grade 2",
        "Grade 3",
        "Grade 4",
        "Grade 5",
        "Grade 6",
        "Grade 5/6"
    ]

    private let weekdays = [
        (2, "Mon"),
        (3, "Tue"),
        (4, "Wed"),
        (5, "Thu"),
        (6, "Fri")
    ]

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(school.name)
                    .font(.largeTitle.bold())

                Divider()

                // MARK: - School

                SectionCard("School") {

                    HStack {

                        Text("School Name")
                            .frame(
                                width: 110,
                                alignment: .leading
                            )

                        TextField(
                            "",
                            text: $school.name
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack {

                        Text("Short Name")
                            .frame(
                                width: 110,
                                alignment: .leading
                            )

                        TextField(
                            "",
                            text: $school.shortName
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                }


                // MARK: - Delivery

                SectionCard("Delivery") {

                    HStack {

                        Text("Cut-off")
                            .frame(
                                width: 110,
                                alignment: .leading
                            )

                        TextField(
                            "",
                            text: $school.orderCutoffTime
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack {

                        Text("Delivery")
                            .frame(
                                width: 110,
                                alignment: .leading
                            )

                        TextField(
                            "",
                            text: $school.deliveryTime
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                }


                // MARK: - Ordering Days

                SectionCard("Ordering Days") {

                    Text(
                        "Choose which days each year level "
                        + "can receive school lunches."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Divider()

                    HStack(spacing: 6) {

                        Text("Year")
                            .fontWeight(.semibold)
                            .frame(
                                width: 80,
                                alignment: .leading
                            )

                        ForEach(
                            weekdays,
                            id: \.0
                        ) { weekday in

                            Text(weekday.1)
                                .font(.caption.bold())
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .center
                                )
                        }
                    }

                    Divider()

                    ForEach(
                        yearLevels,
                        id: \.self
                    ) { yearLevel in

                        HStack(spacing: 6) {

                            Text(yearLevel)
                                .font(.subheadline)
                                .frame(
                                    width: 80,
                                    alignment: .leading
                                )

                            ForEach(
                                weekdays,
                                id: \.0
                            ) { weekday in

                                Toggle(
                                    "",
                                    isOn: orderingDayBinding(
                                        yearLevel: yearLevel,
                                        weekday: weekday.0
                                    )
                                )
                                .toggleStyle(.checkbox)
                                .labelsHidden()
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .center
                                )
                            }
                        }
                    }

                    Divider()

                    Text(
                        "These days determine which delivery "
                        + "dates parents can choose."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }


                // MARK: - Notes

                SectionCard("Notes") {

                    TextField(
                        "Notes",
                        text: $school.notes,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)

                    Toggle(
                        "Active",
                        isOn: $school.isActive
                    )
                }
            }
            .padding(24)
        }
    }


    // MARK: - Ordering Day Binding

    private func orderingDayBinding(
        yearLevel: String,
        weekday: Int
    ) -> Binding<Bool> {

        Binding(

            get: {

                guard let rule = school.orderingRules.first(
                    where: {
                        $0.yearLevel == yearLevel
                    }
                ) else {
                    return false
                }

                return rule.weekdays.contains(weekday)
            },

            set: { isEnabled in

                // Make a complete copy first.
                var updatedSchool = school

                if let index =
                    updatedSchool.orderingRules.firstIndex(
                        where: {
                            $0.yearLevel == yearLevel
                        }
                    ) {

                    if isEnabled {

                        updatedSchool
                            .orderingRules[index]
                            .weekdays
                            .insert(weekday)

                    } else {

                        updatedSchool
                            .orderingRules[index]
                            .weekdays
                            .remove(weekday)
                    }

                } else if isEnabled {

                    updatedSchool.orderingRules.append(
                        SchoolOrderingRule(
                            yearLevel: yearLevel,
                            weekdays: [weekday]
                        )
                    )
                }

                // Assign the whole School back through
                // the @Binding.
                school = updatedSchool
            }
        )
    }
}


#Preview {

    @Previewable
    @State var school = School(
        name: "Burnside Primary School",
        shortName: "BPS"
    )

    SchoolInspector(
        school: $school
    )
}
