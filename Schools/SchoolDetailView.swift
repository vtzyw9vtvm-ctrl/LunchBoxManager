import SwiftUI

struct SchoolDetailView: View {

    @Binding var school: School

    private let yearLevels = [
        "Prep",
        "Grade 1",
        "Grade 2",
        "Grade 3",
        "Grade 4",
        "Grade 5",
        "Grade 6"
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

                // MARK: - School Information

                SectionCard("School Information") {

                    HStack {

                        Text("Name")
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

                    // Column headings

                    HStack(spacing: 8) {

                        Text("Year Level")
                            .fontWeight(.semibold)
                            .frame(
                                width: 120,
                                alignment: .leading
                            )

                        ForEach(
                            weekdays,
                            id: \.0
                        ) { weekday in

                            Text(weekday.1)
                                .font(.caption.bold())
                                .frame(
                                    width: 48,
                                    alignment: .center
                                )
                        }
                    }

                    Divider()

                    ForEach(
                        yearLevels,
                        id: \.self
                    ) { yearLevel in

                        HStack(spacing: 8) {

                            Text(yearLevel)
                                .frame(
                                    width: 120,
                                    alignment: .leading
                                )

                            ForEach(
                                weekdays,
                                id: \.0
                            ) { weekday in

                                Toggle(
                                    "",
                                    isOn: binding(
                                        for: yearLevel,
                                        weekday: weekday.0
                                    )
                                )
                                .toggleStyle(.checkbox)
                                .labelsHidden()
                                .frame(
                                    width: 48,
                                    alignment: .center
                                )
                            }
                        }
                    }

                    Divider()

                    Text(
                        "Changes here control the delivery "
                        + "days available to parents."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }


                // MARK: - School Closures

                SectionCard("School Closures / No Lunch Days") {

                    Text(
                        "Block individual days or date ranges "
                        + "when lunch orders are not available."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if school.closures.isEmpty {

                        Divider()

                        Text("No school closures have been added.")
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

                    HStack {

                        Button {
                            addClosure()
                        } label: {
                            Label(
                                "Add Closure",
                                systemImage: "plus"
                            )
                        }

                        Spacer()
                    }

                    Text(
                        "Closed dates will not be available "
                        + "for parents to select when ordering."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text("Closed From")
                    .frame(
                        width: 110,
                        alignment: .leading
                    )

                DatePicker(
                    "",
                    selection: $school.closures[index].startDate,
                    displayedComponents: .date
                )
                .labelsHidden()

                Text("to")
                    .foregroundStyle(.secondary)

                DatePicker(
                    "",
                    selection: $school.closures[index].endDate,
                    in: school.closures[index].startDate...,
                    displayedComponents: .date
                )
                .labelsHidden()

                Spacer()

                Button(role: .destructive) {
                    removeClosure(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete closure")
            }

            HStack {

                Text("Reason")
                    .frame(
                        width: 110,
                        alignment: .leading
                    )

                TextField(
                    "e.g. School Holidays",
                    text: $school.closures[index].reason
                )
                .textFieldStyle(.roundedBorder)
            }
        }
    }


    // MARK: - School Closures

    private func addClosure() {

        let calendar = Calendar.current
        let today = calendar.startOfDay(
            for: Date()
        )

        let closure = SchoolClosure(
            startDate: today,
            endDate: today,
            reason: ""
        )

        school.closures.append(closure)
    }

    private func removeClosure(
        at index: Int
    ) {

        guard school.closures.indices.contains(index)
        else {
            return
        }

        school.closures.remove(at: index)
    }


    // MARK: - Ordering Day Binding

    private func binding(
        for yearLevel: String,
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

                if let index =
                    school.orderingRules.firstIndex(
                        where: {
                            $0.yearLevel == yearLevel
                        }
                    ) {

                    if isEnabled {

                        school.orderingRules[index]
                            .weekdays
                            .insert(weekday)

                    } else {

                        school.orderingRules[index]
                            .weekdays
                            .remove(weekday)
                    }

                } else if isEnabled {

                    let rule = SchoolOrderingRule(
                        yearLevel: yearLevel,
                        weekdays: [weekday]
                    )

                    school.orderingRules.append(
                        rule
                    )
                }
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

    SchoolDetailView(
        school: $school
    )
}
