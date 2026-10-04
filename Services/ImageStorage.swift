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
    
    // MARK: Cache Remote Image

    func cacheRemoteImage(
        from remoteURL: URL,
        named filename: String
    ) async throws {

        guard !filename.isEmpty else {
            return
        }

        let destination =
            imagesFolder.appendingPathComponent(filename)

        // Already cached — don't download it again.
        if FileManager.default.fileExists(
            atPath: destination.path
        ) {
            return
        }

        let (data, response) =
            try await URLSession.shared.data(
                from: remoteURL
            )

        guard
            let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode),
            NSImage(data: data) != nil
        else {
            throw URLError(.cannotDecodeContentData)
        }

        try data.write(
            to: destination,
            options: .atomic
        )
    }

    // MARK: Image Data

    func imageData(named filename: String) -> Data? {

        guard !filename.isEmpty else {
            return nil
        }

        let url = imagesFolder.appendingPathComponent(filename)

        return try? Data(contentsOf: url)
    }

    }
