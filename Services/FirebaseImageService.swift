import Foundation
import FirebaseStorage

final class FirebaseImageService {

    private let storage = Storage.storage()

    func uploadMenuImage(
        filename: String
    ) async throws -> String {

        guard let imageData =
                ImageStorage.shared.imageData(named: filename) else {
            throw FirebaseImageError.imageNotFound
        }

        let fileExtension =
            (filename as NSString).pathExtension.lowercased()

        let storageReference = storage.reference()
            .child("menu_images")
            .child(filename)

        let metadata = StorageMetadata()

        if fileExtension == "png" {
            metadata.contentType = "image/png"
        } else {
            metadata.contentType = "image/jpeg"
        }

        print("🔥 STORAGE BUCKET:", storageReference.bucket)
        print("🔥 STORAGE PATH:", storageReference.fullPath)
        print("🔥 IMAGE BYTES:", imageData.count)

        let uploadedMetadata = try await storageReference.putDataAsync(
            imageData,
            metadata: metadata
        )

        print("🔥 UPLOAD FINISHED")
        print("🔥 UPLOADED PATH:", uploadedMetadata.path ?? "NO PATH")
        print("🔥 UPLOADED SIZE:", uploadedMetadata.size)

        let downloadURL = try await storageReference.downloadURL()

        print("🔥 DOWNLOAD URL:", downloadURL.absoluteString)

        return downloadURL.absoluteString
    }
}

enum FirebaseImageError: Error {
    case imageNotFound
}
