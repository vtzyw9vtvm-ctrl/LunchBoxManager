import SwiftUI

struct ClassInspector: View {

    @Binding var schoolClass: SchoolClass

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
                            .frame(width: 110, alignment: .leading)

                        TextField("", text: $schoolClass.name)
                            .textFieldStyle(.roundedBorder)

                    }

                }

                // MARK: - Lunch Days

                SectionCard("Lunch Days") {

                    VStack(alignment: .leading, spacing: 12) {

                        Text("School lunches are available for this class on:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {

                            ForEach(SchoolLunchDay.allCases, id: \.self) { day in

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
                                    schoolClass.lunchDays.contains(day)
                                        ? .accentColor
                                        : .gray
                                )                            }
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

        if schoolClass.lunchDays.contains(day) {

            schoolClass.lunchDays.remove(day)

        } else {

            schoolClass.lunchDays.insert(day)

        }
    }

}


#Preview {

    @Previewable
    @State var schoolClass = SchoolClass(
        name: "3A",
        schoolID: UUID()
    )

    ClassInspector(
        schoolClass: $schoolClass
    )

}
