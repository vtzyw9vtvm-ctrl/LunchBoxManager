import SwiftUI
import AppKit

struct CafePhotoPickerCard: View {

    @Binding var imageName: String
    @Binding var imageURL: String

    @State private var isUploading = false
    @State private var uploadError: String?

    private let firebaseImageService = CafeFirebaseImageService()

    var body: some View {

        VStack(spacing: 16) {

            Group {

                if let image = ImageStorage.shared.loadImage(named: imageName) {

                    // Use local image when available
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()

                } else if !imageURL.isEmpty,
                          let url = URL(string: imageURL) {

                    AsyncImage(url: url) { phase in

                        switch phase {

                        case .empty:

                            ZStack {
                                Color.gray.opacity(0.12)
                                ProgressView()
                            }

                        case .success(let image):

                            image
                                .resizable()
                                .scaledToFit()
                                .task {
                                    do {
                                        try await ImageStorage.shared
                                            .cacheRemoteImage(
                                                from: url,
                                                named: imageName
                                            )
                                    } catch {
                                        print(
                                            "❌ CAFE IMAGE CACHE FAILED:",
                                            imageName,
                                            error.localizedDescription
                                        )
                                    }
                                }

                        case .failure:

                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.12))
                                .overlay {
                                    VStack(spacing: 12) {
                                        Image(
                                            systemName:
                                                "exclamationmark.triangle"
                                        )
                                        .font(.system(size: 36))

                                        Text("Photo couldn't be loaded")
                                            .foregroundStyle(.secondary)
                                    }
                                }

                        @unknown default:
                            EmptyView()
                        }
                    }

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

                    uploadError = nil
                    isUploading = true

                    Task {
                        do {
                            let url = try await firebaseImageService
                                .uploadMenuImage(filename: filename)

                            await MainActor.run {
                                imageName = filename
                                imageURL = url
                                isUploading = false

                                print(
                                    "☕️ CAFE IMAGE NAME SET TO:",
                                    imageName
                                )

                                print(
                                    "☕️ CAFE IMAGE URL BINDING SET TO:",
                                    imageURL
                                )
                            }

                            print(
                                "☕️ CAFE MENU IMAGE UPLOADED:",
                                url
                            )

                        } catch {

                            await MainActor.run {
                                uploadError = error.localizedDescription
                                isUploading = false
                            }

                            print(
                                "❌ CAFE MENU IMAGE UPLOAD FAILED:",
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

    CafePhotoPickerCard(
        imageName: $imageName,
        imageURL: $imageURL
    )
}
