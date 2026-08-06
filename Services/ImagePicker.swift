import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class ImagePicker {

    static func pickImage() -> String? {

        let panel = NSOpenPanel()

        panel.allowedContentTypes = [
            UTType.jpeg,
            UTType.png
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK,
              let url = panel.url else {
            return nil
        }

        do {

            return try ImageStorage.shared.saveImage(from: url)

        } catch {

            print(error)

            return nil

        }

    }

}
