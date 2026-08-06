import Foundation
import AppKit

final class ImageStorage {

    static let shared = ImageStorage()

    private init() {}

    private var imagesFolder: URL {

        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let folder = appSupport
            .appendingPathComponent("SchoolLunchManager")
            .appendingPathComponent("Images")

        if !FileManager.default.fileExists(atPath: folder.path) {

            try? FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )

        }

        return folder
    }

    // MARK: Save Image

    func saveImage(from originalURL: URL) throws -> String {

        let filename = UUID().uuidString + "." + originalURL.pathExtension

        let destination = imagesFolder.appendingPathComponent(filename)

        try FileManager.default.copyItem(
            at: originalURL,
            to: destination
        )

        return filename

    }

    // MARK: Load Image

    func loadImage(named filename: String) -> NSImage? {

        let url = imagesFolder.appendingPathComponent(filename)

        return NSImage(contentsOf: url)

    }

}
