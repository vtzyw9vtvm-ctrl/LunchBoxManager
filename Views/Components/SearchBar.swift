import SwiftUI

struct SearchBar: View {

    @Binding var text: String

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search menu items...", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {

                Button {

                    text = ""

                } label: {

                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)

                }
                .buttonStyle(.plain)

            }

        }
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))

    }

}

#Preview {

    @Previewable @State var text = ""

    SearchBar(text: $text)

}
