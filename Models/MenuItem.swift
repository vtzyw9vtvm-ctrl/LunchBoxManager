import Foundation

/// Represents a food or drink item included in a lunch order.
struct MenuItem: Identifiable, Codable, Hashable, Sendable {

    let id: UUID

    /// The original item ID stored inside the Firebase order.
    /// Used when refunding this exact purchased item.
    var firebaseOrderItemID: String?

    var name: String
    var category: String
    var variants: [String]
    var quantity: Int

    /// Number of this item that has already been refunded.
    var refundedQuantity: Int

    /// Dollar amount already refunded for this item.
    var refundedAmount: Double

    var notes: String?

    var isHot: Bool
    var isCold: Bool

    // MARK: - Dietary Information

    var isGlutenFree: Bool
    var isVegan: Bool
    var isVegetarian: Bool
    var isHalal: Bool

    init(
        id: UUID = UUID(),
        firebaseOrderItemID: String? = nil,
        name: String,
        category: String,
        variants: [String] = [],
        quantity: Int = 1,
        refundedQuantity: Int = 0,
        refundedAmount: Double = 0,
        notes: String? = nil,
        isHot: Bool = false,
        isCold: Bool = false,
        isGlutenFree: Bool = false,
        isVegan: Bool = false,
        isVegetarian: Bool = false,
        isHalal: Bool = false
    ) {
        self.id = id
        self.firebaseOrderItemID = firebaseOrderItemID
        self.name = name
        self.category = category
        self.variants = variants
        self.quantity = quantity
        self.refundedQuantity = refundedQuantity
        self.refundedAmount = refundedAmount
        self.notes = notes
        self.isHot = isHot
        self.isCold = isCold

        self.isGlutenFree = isGlutenFree
        self.isVegan = isVegan
        self.isVegetarian = isVegetarian
        self.isHalal = isHalal
    }

    /// Quantity that still needs to be prepared
    /// after any refunds.
    var activeQuantity: Int {
        max(0, quantity - refundedQuantity)
    }

    /// True when the entire item quantity
    /// has been refunded.
    var isFullyRefunded: Bool {
        activeQuantity == 0
    }
}
