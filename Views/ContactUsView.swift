import SwiftUI

struct ContactUsView: View {

    @State private var messages: [SupportMessage] = []
    @State private var selectedMessage: SupportMessage?

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingArchived = false

    private let service =
        FirebaseSupportMessageService()
    
    private var displayedMessages: [SupportMessage] {
        messages.filter { message in
            message.isArchived == showingArchived
        }
    }

    var body: some View {

        VStack(spacing: 0) {


            // MARK: - Header

            PageBannerView(
                title: "Contact Us",
                subtitle: "Messages sent by parents from the LunchBox app",
                systemImage: "envelope.fill",
                color: .lunchBoxTeal
            )

            HStack(spacing: 12) {

                Picker(
                    "Messages",
                    selection: $showingArchived
                ) {
                    Text("Inbox")
                        .tag(false)

                    Text("Archived")
                        .tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 240)

                Spacer()

                Button {
                    Task {
                        await loadMessages()
                    }
                } label: {
                    Label(
                        "Refresh",
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            Divider()

            // MARK: - Content

            if isLoading && messages.isEmpty {

                ProgressView(
                    "Loading messages..."
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            } else if let errorMessage {
                
                ContentUnavailableView(
                    "Unable to Load Messages",
                    systemImage:
                        "exclamationmark.triangle",
                    description:
                        Text(errorMessage)
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                
            } else if displayedMessages.isEmpty {

                ContentUnavailableView(
                    "No Messages",
                    systemImage: "envelope",
                    description: Text(
                        showingArchived
                            ? "Archived conversations will appear here."
                            : "Parent messages will appear here."
                    )
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            } else {

                HSplitView {

                    // MARK: - Message List

                    List(
                        displayedMessages,
                        selection: $selectedMessage
                    ) { message in

                        MessageRowView(
                            message: message
                        )
                        .tag(message)
                    }
                    .frame(
                        minWidth: 300,
                        idealWidth: 360
                    )

                    // MARK: - Message Detail

                    if let selectedMessage {

                        MessageDetailView(
                            message: selectedMessage,
                            onReplySent: {

                                await loadMessages()

                                if let refreshedMessage =
                                    messages.first(
                                        where: {
                                            $0.id == selectedMessage.id
                                        }
                                    ),
                                   refreshedMessage.isArchived
                                        != showingArchived {

                                    self.selectedMessage = nil
                                }
                            }
                        )

                    } else {

                        ContentUnavailableView(
                            "Select a Message",
                            systemImage:
                                "envelope.open",
                            description: Text(
                                "Choose a parent message from the list."
                            )
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                    }
                }
            }
        }

        .task {
            await loadMessages()
        }

        .onChange(of: selectedMessage) {

            guard let selectedMessage else {
                return
            }

            guard selectedMessage.status == "new"
            else {
                return
            }

            Task {

                await markMessageAsRead(
                    selectedMessage
                )
            }
        }
    }

    // MARK: - Load Messages

    private func loadMessages() async {

        isLoading = true
        errorMessage = nil

        do {

            messages =
                try await service.loadMessages()

            if let selectedMessage {

                self.selectedMessage =
                    messages.first(
                        where: {
                            $0.id ==
                                selectedMessage.id
                        }
                    )
            }

            print(
                "📨 SUPPORT MESSAGES LOADED:",
                messages.count
            )

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "📨 SUPPORT MESSAGE ERROR:",
                error.localizedDescription
            )
        }

        isLoading = false
    }

    // MARK: - Mark As Read

    private func markMessageAsRead(
        _ message: SupportMessage
    ) async {

        do {

            try await service.markAsRead(
                messageID: message.id
            )

            if let index =
                messages.firstIndex(
                    where: {
                        $0.id == message.id
                    }
                ) {

                messages[index].status = "read"

                selectedMessage =
                    messages[index]
            }

            print(
                "📨 MESSAGE MARKED AS READ:",
                message.id
            )

        } catch {

            print(
                "📨 MARK AS READ ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Message Row

private struct MessageRowView: View {

    let message: SupportMessage
    private var isUnread: Bool {
        message.status == "new" ||
        message.hasUnreadParentReply
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack {

                Text(
                    message.parentName.isEmpty
                        ? "Parent"
                        : message.parentName
                )
                .font(.system(size: 15))
                .fontWeight(
                    isUnread
                        ? .bold
                        : .regular
                )

                Spacer()

                if message.status == "new" {

                    Circle()
                        .fill(.blue)
                        .frame(
                            width: 8,
                            height: 8
                        )
                }

                if message.status == "replied" {

                    Image(
                        systemName:
                            "arrowshape.turn.up.left.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.green)
                }
            }

            Text(
                message.subject.isEmpty
                    ? "Contact Us"
                    : message.subject
            )
            .font(.system(size: 14))
            .fontWeight(
                isUnread
                    ? .bold
                    : .regular
            )

            Text(message.message)
                .font(
                    .system(
                        size: 13,
                        weight: isUnread
                            ? .bold
                            : .regular
                    )
                )
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {

                Text(
                    message.createdAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )

                Spacer()

                if message.status == "replied" {

                    Text("Replied")
                        .foregroundStyle(.green)
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}


// MARK: - Message Detail

private struct MessageDetailView: View {

    let message: SupportMessage
    let onReplySent: () async -> Void

    @State private var replies: [SupportReply] = []
    @State private var replyText = ""
    @State private var isLoadingReplies = false
    @State private var isSending = false
    @State private var replyError: String?
    @State private var replySent = false

    private let service =
        FirebaseSupportMessageService()

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Header

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                Text(
                    message.subject.isEmpty
                        ? "Contact Us"
                        : message.subject
                )
                .font(.title.bold())

                HStack(spacing: 24) {

                    detailRow(
                        title: "From",
                        value:
                            message.parentName.isEmpty
                                ? "Parent"
                                : message.parentName
                    )

                    if !message.parentEmail.isEmpty {

                        detailRow(
                            title: "Email",
                            value: message.parentEmail
                        )
                    }
                }

                HStack(spacing: 24) {

                    detailRow(
                        title: "Received",
                        value:
                            message.createdAt.formatted(
                                date: .long,
                                time: .shortened
                            )
                    )

                    detailRow(
                        title: "Status",
                        value:
                            message.status.capitalized
                    )
                }
            }
            .padding(24)

            Divider()
            
            HStack {
                Spacer()

                Button {
                    Task {
                        await toggleArchive()
                    }
                } label: {
                    Label(
                        message.isArchived
                            ? "Restore to Inbox"
                            : "Archive",
                        systemImage:
                            message.isArchived
                                ? "tray.and.arrow.up"
                                : "archivebox"
                    )
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // MARK: - Conversation

            ScrollView {

                LazyVStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    // Original parent message

                    conversationBubble(
                        senderName:
                            message.parentName.isEmpty
                                ? "Parent"
                                : message.parentName,
                        text: message.message,
                        date: message.createdAt,
                        isManager: false
                    )

                    // Replies

                    ForEach(replies) { reply in

                        conversationBubble(
                            senderName:
                                reply.isFromManager
                                    ? "LunchBox"
                                    : (
                                        message.parentName.isEmpty
                                            ? "Parent"
                                            : message.parentName
                                    ),
                            text: reply.message,
                            date: reply.createdAt,
                            isManager:
                                reply.isFromManager
                        )
                    }

                    if isLoadingReplies {

                        HStack {

                            Spacer()

                            ProgressView(
                                "Loading conversation..."
                            )

                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding(24)
            }

            Divider()

            // MARK: - Reply Composer

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Text("REPLY TO PARENT")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                TextEditor(
                    text: $replyText
                )
                .font(.body)
                .frame(
                    minHeight: 80,
                    maxHeight: 110
                )
                .padding(8)
                .background(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                    .stroke(
                        Color.secondary.opacity(0.35)
                    )
                )

                HStack {

                    if let replyError {

                        Label(
                            replyError,
                            systemImage:
                                "exclamationmark.triangle"
                        )
                        .foregroundStyle(.red)
                        .font(.caption)
                    }

                    if replySent {

                        Label(
                            "Reply sent",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)
                        .font(.caption)
                    }

                    Spacer()

                    Button {

                        Task {
                            await sendReply()
                        }

                    } label: {

                        if isSending {

                            ProgressView()
                                .controlSize(.small)

                        } else {

                            Label(
                                "Send Reply",
                                systemImage:
                                    "paperplane.fill"
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        replyText
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                            .isEmpty ||
                        isSending
                    )
                }
            }
            .padding(20)
        }

        .task(id: message.id) {
            replyText = ""
            replyError = nil
            replySent = false

            await loadReplies()

            do {
                try await service.markParentRepliesAsRead(
                    messageID: message.id
                )

                await onReplySent()

            } catch {
                print(
                    "💬 MARK PARENT REPLIES READ ERROR:",
                    error.localizedDescription
                )
            }
        }
    }

    // MARK: - Load Replies

    private func loadReplies() async {

        let showLoading =
            replies.isEmpty

        if showLoading {
            isLoadingReplies = true
        }

        do {
            replies = try await service.loadReplies(
                messageID: message.id
            )

            print(
                "💬 SUPPORT REPLIES LOADED:",
                replies.count
            )

        } catch {
            print(
                "💬 SUPPORT REPLIES ERROR:",
                error.localizedDescription
            )
        }

        if showLoading {
            isLoadingReplies = false
        }
    }
    
    @MainActor
    private func toggleArchive() async {

        do {

            if message.isArchived {

                try await service.restoreMessage(
                    messageID: message.id
                )

            } else {

                try await service.archiveMessage(
                    messageID: message.id
                )
            }

            await onReplySent()

        } catch {

            replyError =
                message.isArchived
                    ? "Unable to restore this conversation."
                    : "Unable to archive this conversation."

            print(
                "❌ ARCHIVE ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Send Reply

    private func sendReply() async {

        let trimmedReply =
            replyText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedReply.isEmpty else {
            return
        }

        isSending = true
        replyError = nil
        replySent = false

        do {

            try await service.sendReply(
                messageID: message.id,
                replyText: trimmedReply
            )

            replyText = ""
            replySent = true

            // Immediately reload the conversation
            // so the sent message appears.

            await loadReplies()

            // Refresh the parent message list/status.

            await onReplySent()

            print(
                "📤 SUPPORT REPLY SENT:",
                message.id
            )

        } catch {

            replyError =
                error.localizedDescription

            print(
                "📤 SUPPORT REPLY ERROR:",
                error.localizedDescription
            )
        }

        isSending = false
    }

    // MARK: - Conversation Bubble

    @ViewBuilder
    private func conversationBubble(
        senderName: String,
        text: String,
        date: Date,
        isManager: Bool
    ) -> some View {

        HStack {

            if isManager {
                Spacer(minLength: 100)
            }

            VStack(
                alignment:
                    isManager
                        ? .trailing
                        : .leading,
                spacing: 5
            ) {

                Text(senderName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(
                        isManager
                            ? .blue
                            : .green
                    )

                Text(text)
                    .font(.system(size: 16))
                    .textSelection(.enabled)

                Text(
                    date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(
                    cornerRadius: 12
                )
                .fill(
                    isManager
                        ? Color.blue.opacity(0.10)
                        : Color.green.opacity(0.10)
                )
            )
            .frame(
                maxWidth: 500,
                alignment:
                    isManager
                        ? .trailing
                        : .leading
            )

            if !isManager {
                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Detail Row

    private func detailRow(
        title: String,
        value: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 8
        ) {

            Text(title)
                .foregroundStyle(.secondary)

            Text(value)
                .textSelection(.enabled)
        }
        .font(.callout)
    }
}


#Preview {
    ContactUsView()
}

#Preview {
    ContactUsView()
}
