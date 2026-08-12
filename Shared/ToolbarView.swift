import SwiftUI

struct ToolbarView: View {

    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {

        HStack {

            Text(title)
                .font(.headline)

            Spacer()

            Button(action: action) {

                Image(systemName: systemImage)
                    .font(.title3)

            }
            .buttonStyle(.borderless)

        }
        .padding()

    }

}

#Preview {

    ToolbarView(
        title: "Menu",
        systemImage: "plus"
    ) {

    }

}
