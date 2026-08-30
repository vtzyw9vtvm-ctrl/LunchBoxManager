import Foundation

struct SupportMessage: Identifiable, Hashable {

    let id: String

    var parentId: String
    var parentName: String
    var parentEmail: String
    var subject: String
    var message: String

    var createdAt: Date

    var status: String
    var hasUnreadParentReply: Bool = false
    var isArchived: Bool = false
}
