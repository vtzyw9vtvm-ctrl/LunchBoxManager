import SwiftUI

struct SchoolRowView: View {

    let school: School

    var isSelected = false

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: "building.2.fill")
                .font(.system(size: 34))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {

                Text(school.name)
                    .font(.headline)

                Text(school.shortName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Spacer()

            if school.isActive {

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

    SchoolRowView(
        school: School(
            name: "Burnside Primary School",
            shortName: "BPS"
        )
    )

}
