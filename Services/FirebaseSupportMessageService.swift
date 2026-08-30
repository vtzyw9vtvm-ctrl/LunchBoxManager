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

        var messages: [SupportMessage] = []

        for document in snapshot.documents {

            let data = document.data()

            let createdAt: Date

            if let timestamp =
                data["createdAt"] as? Timestamp {

                createdAt = timestamp.dateValue()

            } else {

                createdAt = Date()
            }

            // Check whether this conversation has
            // an unread reply from the parent.

            let repliesSnapshot = try await document.reference
                .collection("replies")
                .whereField(
                    "senderType",
                    isEqualTo: "parent"
                )
                .getDocuments()

            let hasUnreadParentReply =
                repliesSnapshot.documents.contains { reply in

                    let replyData = reply.data()

                    return
                        (replyData["readByManager"] as? Bool)
                            != true
                }

            let message = SupportMessage(
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
                    data["status"] as? String ?? "new",
                hasUnreadParentReply:
                    hasUnreadParentReply,
                isArchived:
                    data["isArchived"] as? Bool ?? false
                )

            messages.append(message)
        }

        return messages
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
    
    // MARK: - Live Unread Parent Reply Listener

    func listenForUnreadParentReplies(
        onChange: @escaping (Int) -> Void
    ) -> ListenerRegistration {

        print("💬 STARTING LIVE PARENT REPLY LISTENER")

        return db
            .collectionGroup("replies")
            .whereField(
                "senderType",
                isEqualTo: "parent"
            )
            .addSnapshotListener { snapshot, error in

                if let error {
                    print(
                        "❌ LIVE PARENT REPLY LISTENER ERROR:",
                        error.localizedDescription
                    )
                    return
                }

                let documents =
                    snapshot?.documents ?? []

                let unreadCount =
                    documents.filter { document in

                        let data = document.data()

                        return
                            (data["readByManager"] as? Bool)
                                != true
                    }
                    .count

                print(
                    "💬 PARENT REPLY SNAPSHOT:",
                    documents.count,
                    "TOTAL /",
                    unreadCount,
                    "UNREAD"
                )

                Task { @MainActor in
                    onChange(unreadCount)
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
    
    // MARK: - Load Conversation Replies

    func loadReplies(
        messageID: String
    ) async throws -> [SupportReply] {

        let snapshot = try await db
            .collection("supportMessages")
            .document(messageID)
            .collection("replies")
            .order(
                by: "createdAt",
                descending: false
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

            return SupportReply(
                id: document.documentID,
                message:
                    data["message"] as? String ?? "",
                senderType:
                    data["senderType"] as? String ?? "",
                createdAt: createdAt,
                readByParent:
                    data["readByParent"] as? Bool ?? false,
                readByManager:
                    data["readByManager"] as? Bool ?? false
            )
        }
    }
    
    // MARK: - Mark Parent Replies As Read

    func markParentRepliesAsRead(
        messageID: String
    ) async throws {

        let snapshot = try await db
            .collection("supportMessages")
            .document(messageID)
            .collection("replies")
            .whereField(
                "senderType",
                isEqualTo: "parent"
            )
            .getDocuments()

        let unreadReplies =
            snapshot.documents.filter { document in

                let data = document.data()

                return
                    (data["readByManager"] as? Bool)
                        != true
            }

        guard !unreadReplies.isEmpty else {
            return
        }

        let batch = db.batch()

        for reply in unreadReplies {
            batch.updateData(
                [
                    "readByManager": true,
                    "readByManagerAt":
                        FieldValue.serverTimestamp()
                ],
                forDocument: reply.reference
            )
        }

        try await batch.commit()

        print(
            "💬 MANAGER MARKED",
            unreadReplies.count,
            "PARENT REPLY/REPLIES AS READ"
        )
    }
    // MARK: - Archive Message

    func archiveMessage(
        messageID: String
    ) async throws {

        try await db
            .collection("supportMessages")
            .document(messageID)
            .updateData([
                "isArchived": true,
                "archivedAt": FieldValue.serverTimestamp()
            ])
    }


    // MARK: - Restore Message To Inbox

    func restoreMessage(
        messageID: String
    ) async throws {

        try await db
            .collection("supportMessages")
            .document(messageID)
            .updateData([
                "isArchived": false,
                "archivedAt": FieldValue.delete()
            ])
    }
    
}
