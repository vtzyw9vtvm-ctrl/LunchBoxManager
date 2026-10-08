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
        "Grade 5/6",
        "Staff"
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


                // MARK: - School Closures

                SectionCard("No Lunch Days") {

                    Text(
                        "Block a single day or a date range "
                        + "when lunch orders are unavailable."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if school.closures.isEmpty {

                        Divider()

                        Text("No blocked dates.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    } else {

                        Divider()

                        ForEach(
                            Array(school.closures.enumerated()),
                            id: \.element.id
                        ) { index, _ in

                            closureRow(index: index)

                            if index < school.closures.count - 1 {
                                Divider()
                            }
                        }
                    }

                    Divider()

                    Button {
                        addClosure()
                    } label: {
                        Label(
                            "Add No Lunch Day",
                            systemImage: "plus"
                        )
                    }

                    Text(
                        "Parents will not be able to select "
                        + "these dates for lunch orders."
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


    // MARK: - Closure Row

    @ViewBuilder
    private func closureRow(
        index: Int
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("From")
                    .frame(
                        width: 55,
                        alignment: .leading
                    )

                DatePicker(
                    "",
                    selection: closureStartBinding(
                        index: index
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()

                Spacer()
            }

            HStack {

                Text("To")
                    .frame(
                        width: 55,
                        alignment: .leading
                    )

                DatePicker(
                    "",
                    selection: closureEndBinding(
                        index: index
                    ),
                    in: school.closures[index].startDate...,
                    displayedComponents: .date
                )
                .labelsHidden()

                Spacer()
            }

            HStack {

                Text("Reason")
                    .frame(
                        width: 55,
                        alignment: .leading
                    )

                TextField(
                    "e.g. School Holidays",
                    text: closureReasonBinding(
                        index: index
                    )
                )
                .textFieldStyle(.roundedBorder)

                Button(role: .destructive) {
                    removeClosure(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete no lunch day")
            }
        }
    }


    // MARK: - Closure Bindings

    private func closureStartBinding(
        index: Int
    ) -> Binding<Date> {

        Binding(

            get: {
                school.closures[index].startDate
            },

            set: { newDate in

                var updatedSchool = school

                updatedSchool.closures[index].startDate =
                    newDate

                if updatedSchool.closures[index].endDate
                    < newDate {

                    updatedSchool.closures[index].endDate =
                        newDate
                }

                school = updatedSchool
            }
        )
    }


    private func closureEndBinding(
        index: Int
    ) -> Binding<Date> {

        Binding(

            get: {
                school.closures[index].endDate
            },

            set: { newDate in

                var updatedSchool = school

                updatedSchool.closures[index].endDate =
                    newDate

                school = updatedSchool
            }
        )
    }


    private func closureReasonBinding(
        index: Int
    ) -> Binding<String> {

        Binding(

            get: {
                school.closures[index].reason
            },

            set: { newReason in

                var updatedSchool = school

                updatedSchool.closures[index].reason =
                    newReason

                school = updatedSchool
            }
        )
    }


    // MARK: - Closure Actions

    private func addClosure() {

        var updatedSchool = school

        let calendar = Calendar.current
        let today = calendar.startOfDay(
            for: Date()
        )

        updatedSchool.closures.append(
            SchoolClosure(
                startDate: today,
                endDate: today
            )
        )

        school = updatedSchool
    }


    private func removeClosure(
        at index: Int
    ) {

        guard school.closures.indices.contains(index)
        else {
            return
        }

        var updatedSchool = school
        updatedSchool.closures.remove(at: index)
        school = updatedSchool
    }


    // MARK: - Ordering Day Binding

    private func orderingDayBinding(
        yearLevel: String,
        weekday: Int
    ) -> Binding<Bool> {

        Binding(

            get: {

                guard let rule =
                    school.orderingRules.first(
                        where: {
                            $0.yearLevel == yearLevel
                        }
                    )
                else {
                    return false
                }

                return rule.weekdays.contains(
                    weekday
                )
            },

            set: { isEnabled in

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
