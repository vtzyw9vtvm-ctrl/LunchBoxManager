import SwiftUI

struct ReorderDropDelegate: DropDelegate {

    let itemID: UUID
    let itemIndex: Int

    @Binding var draggedID: UUID?
    @Binding var hoveredID: UUID?

    let onMove: (UUID, Int) -> Void

    func dropEntered(info: DropInfo) {

        hoveredID = itemID

        guard let draggedID else { return }
        guard draggedID != itemID else { return }

        onMove(
            draggedID,
            itemIndex
        )

    }

    func performDrop(info: DropInfo) -> Bool {

        hoveredID = nil
        draggedID = nil

        return true

    }

    func dropExited(info: DropInfo) {

        hoveredID = nil

    }

}
