import SwiftUI

struct StudentRowView: View {

    let student: Student

    var isSelected = false

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: "person.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {

                Text(student.fullName)
                    .font(.headline)

                Text(student.classID == nil ? "No Class Assigned" : student.classID!.uuidString.prefix(8))
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Spacer()

            if student.isActive {

                Text("ACTIVE")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)

            }

        }
        .padding(16)

        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isSelected
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear
                )
        )

        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.15))
        )

    }

}

#Preview {

    StudentRowView(
        student: Student(
            firstName: "Ava",
            lastName: "Nguyen"
        )
    )

}
