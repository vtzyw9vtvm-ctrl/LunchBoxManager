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
                    "sortOrder": schoolClass.sortOrder,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    // MARK: - Delete Class

    func deleteClass(_ schoolClass: SchoolClass) async throws {

        try await db
            .collection("school_classes")
            .document(schoolClass.id.uuidString)
            .delete()
    }
}
