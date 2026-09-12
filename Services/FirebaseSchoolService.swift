import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseSchoolService {

    private let db = Firestore.firestore()

    // MARK: - Save School

    func saveSchool(_ school: School) async throws {

        let orderingRules = school.orderingRules.map { rule in
            [
                "yearLevel": rule.yearLevel,
                "weekdays": Array(rule.weekdays).sorted()
            ] as [String: Any]
        }

        let closures = school.closures.map { closure in
            [
                "id": closure.id.uuidString,
                "startDate": dateString(
                    from: closure.startDate
                ),
                "endDate": dateString(
                    from: closure.endDate
                ),
                "reason": closure.reason
            ] as [String: Any]
        }

        try await db
            .collection("schools")
            .document(school.id.uuidString)
            .setData(
                [
                    "id": school.id.uuidString,
                    "name": school.name,
                    "shortName": school.shortName,
                    "isActive": school.isActive,
                    "orderCutoffTime": school.orderCutoffTime,
                    "deliveryTime": school.deliveryTime,
                    "notes": school.notes,
                    "orderingRules": orderingRules,
                    "closures": closures,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }


    // MARK: - Save All Schools

    func saveSchools(_ schools: [School]) async throws {

        for school in schools {
            try await saveSchool(school)
        }
    }


    // MARK: - Date Formatting

    private func dateString(
        from date: Date
    ) -> String {

        let formatter = DateFormatter()

        formatter.calendar = Calendar(
            identifier: .gregorian
        )

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.timeZone = TimeZone(
            identifier: "Australia/Melbourne"
        )

        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(
            from: date
        )
    }
}
