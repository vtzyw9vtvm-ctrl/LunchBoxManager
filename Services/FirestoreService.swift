import Foundation
import FirebaseFirestore

final class FirestoreService {

    private let db = Firestore.firestore()

    func testConnection() async {

        do {

            let document = try await db
                .collection("school_menu")
                .document("current")
                .getDocument()

            if let data = document.data() {

                print("🔥 FIREBASE TEST:", data)

            } else {

                print("🔥 FIREBASE TEST: Document exists but has no data")

            }

        } catch {

            print("🔥 FIREBASE ERROR:", error.localizedDescription)

        }

    }
}
