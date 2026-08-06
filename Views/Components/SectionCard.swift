import SwiftUI

struct SectionCard<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text(title)
                .font(.title3.bold())

            content

        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 6)

    }
}

#Preview {

    SectionCard("Example") {
        Text("Hello")
    }

}
