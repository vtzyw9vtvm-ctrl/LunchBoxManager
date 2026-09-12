import Foundation
import FirebaseFunctions

@MainActor
final class FirebaseAdminService {

    private let functions = Functions.functions(
        region: "australia-southeast1"
    )

    // MARK: - Load Admin Users

    func loadAdminUserIDs() async throws -> Set<String> {

        let result = try await functions
            .httpsCallable("getLunchBoxAdminUsers")
            .call()

        guard let data =
                result.data as? [String: Any],
              let ids =
                data["adminUserIds"] as? [String] else {

            throw NSError(
                domain: "LunchBoxManager",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase returned an invalid administrator response."
                ]
            )
        }

        return Set(ids)
    }

    // MARK: - Change Admin Access

    func setAdminAccess(
        userID: String,
        makeAdmin: Bool
    ) async throws {

        let result = try await functions
            .httpsCallable("setLunchBoxAdminAccess")
            .call([
                "userId": userID,
                "makeAdmin": makeAdmin
            ])

        guard let data =
                result.data as? [String: Any],
              let success =
                data["success"] as? Bool,
              success else {

            throw NSError(
                domain: "LunchBoxManager",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase could not update administrator access."
                ]
            )
        }
    }
    // MARK: - Delete User Account

    func deleteUser(
        userID: String
    ) async throws {

        let result = try await functions
            .httpsCallable("deleteLunchBoxUser")
            .call([
                "userId": userID
            ])

        guard let data =
                result.data as? [String: Any],
              let success =
                data["success"] as? Bool,
              success else {

            throw NSError(
                domain: "LunchBoxManager",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase could not delete the account."
                ]
            )
        }
    }
}
