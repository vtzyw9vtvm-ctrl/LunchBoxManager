import Foundation

struct SupportReply: Identifiable, Hashable {
    let id: String
    let message: String
    let senderType: String
    let createdAt: Date
    let readByParent: Bool
    let readByManager: Bool

    var isFromManager: Bool {
        senderType == "manager"
    }

    var isFromParent: Bool {
        senderType == "parent"
    }
}
