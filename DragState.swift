import SwiftUI

@Observable
final class DragState {

    var draggedID: UUID?
    var hoveredIndex: Int?

}
