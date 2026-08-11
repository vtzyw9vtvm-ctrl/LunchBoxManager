import SwiftUI

struct DragHandle: View {

    var action: (() -> Void)? = nil

    @GestureState private var pressed = false

    var body: some View {

        Image(systemName: "line.3.horizontal")
            .font(.title2)
            .foregroundStyle(pressed ? .primary : .secondary)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        pressed
                        ? Color.accentColor.opacity(0.15)
                        : .clear
                    )
            )
            .scaleEffect(pressed ? 1.15 : 1.0)
            .gesture(
                LongPressGesture(minimumDuration: 0.15)
                    .updating($pressed) { value, state, _ in
                        state = value
                    }
                    .onEnded { _ in
                        action?()
                    }
            )

    }

}

#Preview {
    DragHandle()
}
