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
}
