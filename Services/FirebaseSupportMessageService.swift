import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseSupportMessageService {

    private let db = Firestore.firestore()

    // MARK: - Load Messages

    func loadMessages() async throws -> [SupportMessage] {

        let snapshot = try await db
            .collection("supportMessages")
            .order(
                by: "createdAt",
                descending: true
            )
            .getDocuments()

        return snapshot.documents.map { document in

            let data = document.data()

            let createdAt: Date

            if let timestamp =
                data["createdAt"] as? Timestamp {

                createdAt = timestamp.dateValue()

            } else {

                createdAt = Date()
            }

            return SupportMessage(
                id: document.documentID,
                parentId:
                    data["parentId"] as? String ?? "",
                parentName:
                    data["parentName"] as? String ?? "",
                parentEmail:
                    data["parentEmail"] as? String ?? "",
                subject:
                    data["subject"] as? String ?? "",
                message:
                    data["message"] as? String ?? "",
                createdAt: createdAt,
                status:
                    data["status"] as? String ?? "new"
            )
        }
    }

    // MARK: - Mark Message As Read

    func markAsRead(
        messageID: String
    ) async throws {

        try await db
            .collection("supportMessages")
            .document(messageID)
            .updateData([
                "status": "read",
                "readAt": FieldValue.serverTimestamp()
            ])
    }

    // MARK: - Unread Message Count

    func unreadCount() async throws -> Int {

        let snapshot = try await db
            .collection("supportMessages")
            .whereField(
                "status",
                isEqualTo: "new"
            )
            .getDocuments()

        return snapshot.documents.count
    }

    // MARK: - Live Unread Message Listener

    func listenForUnreadCount(
        onChange: @escaping (Int) -> Void
    ) -> ListenerRegistration {

        db
            .collection("supportMessages")
            .whereField(
                "status",
                isEqualTo: "new"
            )
            .addSnapshotListener { snapshot, error in

                if let error {

                    print(
                        "📩 LIVE UNREAD LISTENER ERROR:",
                        error.localizedDescription
                    )

                    return
                }

                let count =
                    snapshot?.documents.count ?? 0

                Task { @MainActor in

                    onChange(count)
                }
            }
    }
    // MARK: - Send Reply

    func sendReply(
        messageID: String,
        replyText: String
    ) async throws {

        let trimmedReply =
            replyText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedReply.isEmpty else {
            return
        }

        let replyReference = db
            .collection("supportMessages")
            .document(messageID)
            .collection("replies")
            .document()

        try await replyReference.setData([
            "message": trimmedReply,
            "senderType": "manager",
            "createdAt": FieldValue.serverTimestamp(),
            "readByParent": false
        ])

        // Also update the parent support message so we
        // know that this enquiry has been replied to.
        try await db
            .collection("supportMessages")
            .document(messageID)
            .updateData([
                "status": "replied",
                "repliedAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
}
