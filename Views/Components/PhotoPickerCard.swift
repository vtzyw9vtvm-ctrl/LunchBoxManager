import SwiftUI
import AppKit

struct PhotoPickerCard: View {

    @Binding var imageName: String

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

                    if let filename = ImagePicker.pickImage() {
                        imageName = filename
                    }

                } label: {

                    Label("Choose Photo", systemImage: "photo")

                }

                if !imageName.isEmpty {

                    Button(role: .destructive) {

                        imageName = ""

                    } label: {

                        Label("Remove", systemImage: "trash")

                    }

                }

                Spacer()

            }

        }

    }

}

#Preview {

    @Previewable @State var image = ""

    PhotoPickerCard(imageName: $image)

}
