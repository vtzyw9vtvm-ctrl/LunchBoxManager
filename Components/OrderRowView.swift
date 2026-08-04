import SwiftUI

/// Displays a compact summary of one student's portion of an imported lunch order.
struct OrderRowView: View {
    var row: OrderBrowserRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.studentOrder.student.fullName.isEmpty ? "Unnamed student" : row.studentOrder.student.fullName)
                    .font(.headline)
                Spacer()
                Text(row.orderNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text([row.school.name.nonEmptyValue, row.studentOrder.schoolClass?.name.nonEmptyValue].compactMap { $0 }.joined(separator: " - "))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(row.studentOrder.items.map(\.displaySummary).joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private extension String {
    var nonEmptyValue: String? {
        isEmpty ? nil : self
    }
}

private extension MenuItem {
    var displaySummary: String {
        let choice = variants.first.map { " (\($0))" } ?? ""
        return "\(quantity)x \(name)\(choice)"
    }
}

#Preview {
    let school = School(name: "North Primary School", shortName: "NPS")
    let schoolClass = SchoolClass(name: "Year 3B", yearLevel: "Year 3B", schoolID: school.id)
    let studentOrder = StudentOrder(
        student: Student(firstName: "Ava", lastName: "Nguyen", fullName: "Ava Nguyen", classID: schoolClass.id),
        schoolClass: schoolClass,
        items: [MenuItem(name: "Chicken Wrap", category: "Lunch", variants: ["Tomato"], quantity: 2)]
    )

    OrderRowView(
        row: OrderBrowserRow(
            orderID: UUID(),
            orderNumber: "1001",
            school: school,
            orderDate: Date(),
            notes: "Deliver to office",
            studentOrder: studentOrder
        )
    )
    .padding()
}
