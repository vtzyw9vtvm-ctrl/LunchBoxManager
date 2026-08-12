import SwiftUI

struct ClassRowView: View {

    let schoolClass: SchoolClass

    var isSelected = false

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: "graduationcap.fill")
                .font(.system(size: 32))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 4) {

                Text(schoolClass.name)
                    .font(.headline)

                Text("School Class")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Spacer()

            if schoolClass.isActive {

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

    ClassRowView(
        schoolClass: SchoolClass(
            name: "3A",
            schoolID: UUID()
        )
    )

}
