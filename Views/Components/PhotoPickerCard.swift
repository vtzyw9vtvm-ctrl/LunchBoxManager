import SwiftUI
import AppKit

struct PhotoPickerCard: View {

    @Binding var imageName: String
    @Binding var imageURL: String

    @State private var isUploading = false
    @State private var uploadError: String?

    private let firebaseImageService = FirebaseImageService()

    var body: some View {

        VStack(spacing: 16) {

            Group {

                if let image = ImageStorage.shared.loadImage(named: imageName) {

                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()

                } else {

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.12))
                        .overlay {

                            VStack(spacing: 12) {

                                Image(systemName: "photo")
                                    .font(.system(size: 42))

                                Text("No Photo Selected")
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack {

                Button {

                    guard let filename = ImagePicker.pickImage() else {
                        return
                    }

                    imageName = filename
                    imageURL = ""
                    uploadError = nil
                    isUploading = true

                    Task {

                        do {

                            let url = try await firebaseImageService
                                .uploadMenuImage(filename: filename)

                            await MainActor.run {
                                imageURL = url
                                isUploading = false

                                print("🔥 IMAGE URL BINDING SET TO:", imageURL)
                            }

                            print("🔥 MENU IMAGE UPLOADED:", url)

                        } catch {

                            await MainActor.run {
                                uploadError = error.localizedDescription
                                isUploading = false
                            }

                            print(
                                "🔥 MENU IMAGE UPLOAD FAILED:",
                                error.localizedDescription
                            )
                        }
                    }

                } label: {

                    Label(
                        isUploading ? "Uploading..." : "Choose Photo",
                        systemImage: "photo"
                    )
                }
                .disabled(isUploading)

                if !imageName.isEmpty {

                    Button(role: .destructive) {

                        imageName = ""
                        imageURL = ""
                        uploadError = nil

                    } label: {

                        Label("Remove", systemImage: "trash")
                    }
                }

                Spacer()

                if isUploading {

                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let uploadError {

                Text("Upload failed: \(uploadError)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {

    @Previewable @State var imageName = ""
    @Previewable @State var imageURL = ""

    PhotoPickerCard(
        imageName: $imageName,
        imageURL: $imageURL
    )
}
