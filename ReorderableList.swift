import SwiftUI
import UniformTypeIdentifiers

struct ReorderableList<Item: Identifiable, Content: View>: View where Item.ID == UUID {

    let items: [Item]
    let onMove: (UUID, Int) -> Void
    let content: (Item) -> Content

    @State private var draggedID: UUID?
    @State private var hoveredID: UUID?

    init(
        items: [Item],
        onMove: @escaping (UUID, Int) -> Void,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.onMove = onMove
        self.content = content
    }

    var body: some View {

        ScrollView {

            LazyVStack(spacing: 12) {

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in

                    VStack(spacing: 0) {

                        if hoveredID == item.id,
                           draggedID != item.id {

                            Rectangle()
                                .fill(.blue)
                                .frame(height: 3)
                                .padding(.bottom, 6)

                        }

                        content(item)
                            .scaleEffect(draggedID == item.id ? 1.02 : 1.0)
                            .opacity(draggedID == item.id ? 0.55 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: draggedID)
                            .onDrag {

                                draggedID = item.id

                                return NSItemProvider(
                                    object: item.id.uuidString as NSString
                                )

                            }
                            .onDrop(
                                of: [UTType.plainText],
                                delegate: ReorderDropDelegate(
                                    itemID: item.id,
                                    itemIndex: index,
                                    draggedID: $draggedID,
                                    hoveredID: $hoveredID,
                                    onMove: { id, newIndex in

                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                            onMove(id, newIndex)
                                        }

                                    }
                                )
                            )

                    }

                }

            }
            .padding()

        }

    }

}
