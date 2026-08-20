import Foundation
import FirebaseFirestore
import Observation

@MainActor
@Observable
final class MenuManager {

    private let db = Firestore.firestore()

    private(set) var menuData: [String: Any] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func loadMenuFromFirebase() async {

        isLoading = true
        errorMessage = nil

        do {

            let document = try await db
                .collection("school_menu")
                .document("current")
                .getDocument()

            if let data = document.data() {

                menuData = data

                print("🔥 MENU LOADED FROM FIREBASE:", data)

            } else {

                menuData = [:]

                print("🔥 No school menu found in Firebase")

            }

        } catch {

            errorMessage = error.localizedDescription

            print(
                "🔥 MENU FIREBASE ERROR:",
                error.localizedDescription
            )
        }

        isLoading = false
    }
}
