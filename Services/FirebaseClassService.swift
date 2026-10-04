import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseClassService {

    private let db = Firestore.firestore()

    // MARK: - Save Class

    func saveClass(_ schoolClass: SchoolClass) async throws {

        try await db
            .collection("school_classes")
            .document(schoolClass.id.uuidString)
            .setData(
                [
                    "id": schoolClass.id.uuidString,
                    "name": schoolClass.name,
                    "yearLevel": schoolClass.yearLevel,
                    "schoolID": schoolClass.schoolID.uuidString,
                    "isActive": schoolClass.isActive,
                    "lunchDays": schoolClass.lunchDays
                        .map { $0.rawValue }
                        .sorted(),
                    "sortOrder": schoolClass.sortOrder,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    // MARK: - Load Classes

    func loadClasses() async throws -> [SchoolClass] {

        let snapshot = try await db
            .collection("school_classes")
            .getDocuments()

        var classes: [SchoolClass] = []

        for document in snapshot.documents {

            let data = document.data()

            guard
                let idString = data["id"] as? String,
                let id = UUID(uuidString: idString),
                let schoolIDString = data["schoolID"] as? String,
                let schoolID = UUID(uuidString: schoolIDString)
            else {
                continue
            }

            let lunchDayNumbers =
                data["lunchDays"] as? [Int] ?? []

            let lunchDays: Set<SchoolLunchDay>

            if lunchDayNumbers.isEmpty {

                // Older Firebase records did not contain lunchDays.
                lunchDays = Set(SchoolLunchDay.allCases)

            } else {

                lunchDays = Set(
                    lunchDayNumbers.compactMap {
                        SchoolLunchDay(rawValue: $0)
                    }
                )
            }

            let schoolClass = SchoolClass(
                id: id,
                name: data["name"] as? String ?? "",
                yearLevel: data["yearLevel"] as? String ?? "",
                schoolID: schoolID,
                isActive: data["isActive"] as? Bool ?? true,
                lunchDays: lunchDays,
                sortOrder: data["sortOrder"] as? Int ?? 0
            )

            classes.append(schoolClass)
        }

        return classes.sorted {

            if $0.schoolID == $1.schoolID {
                return $0.sortOrder < $1.sortOrder
            }

            return $0.schoolID.uuidString <
                $1.schoolID.uuidString
        }
    }
    
    // MARK: - Delete Class

    func deleteClass(_ schoolClass: SchoolClass) async throws {

        try await db
            .collection("school_classes")
            .document(schoolClass.id.uuidString)
            .delete()
    }
}
