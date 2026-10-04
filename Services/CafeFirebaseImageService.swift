import Foundation
import FirebaseCore
import FirebaseStorage

final class CafeFirebaseImageService {

    private let storage: Storage

    init() {
        let cafeApp: FirebaseApp

        if let existingApp = FirebaseApp.app(name: "EspressoCafe") {
            cafeApp = existingApp
        } else {
            guard
                let plistPath = Bundle.main.path(
                    forResource: "GoogleService-Info-Espresso",
                    ofType: "plist"
                ),
                let options = FirebaseOptions(contentsOfFile: plistPath)
            else {
                fatalError(
                    "Could not load the Espresso Cafe Firebase configuration."
                )
            }

            FirebaseApp.configure(
                name: "EspressoCafe",
                options: options
            )

            guard let configuredApp =
                FirebaseApp.app(name: "EspressoCafe")
            else {
                fatalError(
                    "Could not configure the Espresso Cafe Firebase app."
                )
            }

            cafeApp = configuredApp
        }

        storage = Storage.storage(app: cafeApp)
    }

    func uploadMenuImage(
        filename: String
    ) async throws -> String {

        guard let imageData =
                ImageStorage.shared.imageData(named: filename) else {
            throw CafeFirebaseImageError.imageNotFound
        }

        let fileExtension =
            (filename as NSString).pathExtension.lowercased()

        let storageReference = storage.reference()
            .child("cafe_menu_images")
            .child(filename)

        let metadata = StorageMetadata()

        if fileExtension == "png" {
            metadata.contentType = "image/png"
        } else {
            metadata.contentType = "image/jpeg"
        }

        print("☕️ CAFE STORAGE BUCKET:", storageReference.bucket)
        print("☕️ CAFE STORAGE PATH:", storageReference.fullPath)
        print("☕️ CAFE IMAGE BYTES:", imageData.count)

        let uploadedMetadata = try await storageReference.putDataAsync(
            imageData,
            metadata: metadata
        )

        print("☕️ CAFE IMAGE UPLOAD FINISHED")
        print(
            "☕️ CAFE UPLOADED PATH:",
            uploadedMetadata.path ?? "NO PATH"
        )
        print(
            "☕️ CAFE UPLOADED SIZE:",
            uploadedMetadata.size
        )

        let downloadURL = try await storageReference.downloadURL()

        print(
            "☕️ CAFE DOWNLOAD URL:",
            downloadURL.absoluteString
        )

        return downloadURL.absoluteString
    }
}

enum CafeFirebaseImageError: Error {
    case imageNotFound
}
