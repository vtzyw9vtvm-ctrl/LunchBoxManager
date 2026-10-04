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

    // MARK: - Load Schools

    func loadSchools() async throws -> [School] {

        let snapshot = try await db
            .collection("schools")
            .getDocuments()

        var schools: [School] = []

        for document in snapshot.documents {

            let data = document.data()

            guard
                let idString = data["id"] as? String,
                let id = UUID(uuidString: idString)
            else {
                continue
            }

            let orderingRuleData =
                data["orderingRules"] as? [[String: Any]] ?? []

            let orderingRules: [SchoolOrderingRule] =
                orderingRuleData.map { ruleData in

                    let yearLevel =
                        ruleData["yearLevel"] as? String ?? ""

                    let weekdayNumbers =
                        ruleData["weekdays"] as? [Int] ?? []

                    return SchoolOrderingRule(
                        yearLevel: yearLevel,
                        weekdays: Set(weekdayNumbers)
                    )
                }

            let closureData =
                data["closures"] as? [[String: Any]] ?? []

            let closures: [SchoolClosure] =
                closureData.compactMap { closureData in

                    guard
                        let startString =
                            closureData["startDate"] as? String,
                        let endString =
                            closureData["endDate"] as? String,
                        let startDate = date(
                            from: startString
                        ),
                        let endDate = date(
                            from: endString
                        )
                    else {
                        return nil
                    }

                    let closureID: UUID

                    if let idString =
                        closureData["id"] as? String,
                       let existingID =
                        UUID(uuidString: idString) {

                        closureID = existingID

                    } else {

                        closureID = UUID()
                    }

                    return SchoolClosure(
                        id: closureID,
                        startDate: startDate,
                        endDate: endDate,
                        reason:
                            closureData["reason"] as? String ?? ""
                    )
                }

            let school = School(
                id: id,
                name:
                    data["name"] as? String ?? "",
                shortName:
                    data["shortName"] as? String ?? "",
                isActive:
                    data["isActive"] as? Bool ?? true,
                orderCutoffTime:
                    data["orderCutoffTime"] as? String
                    ?? "8:30 AM",
                deliveryTime:
                    data["deliveryTime"] as? String
                    ?? "12:30 PM",
                notes:
                    data["notes"] as? String ?? "",
                orderingRules: orderingRules,
                closures: closures
            )

            schools.append(school)
        }

        return schools.sorted {
            $0.name.localizedCaseInsensitiveCompare(
                $1.name
            ) == .orderedAscending
        }
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
    
    private func date(
        from string: String
    ) -> Date? {

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

        return formatter.date(
            from: string
        )
    }
}
