import SwiftUI

struct ContactUsView: View {

    @State private var messages: [SupportMessage] = []
    @State private var selectedMessage: SupportMessage?

    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service =
        FirebaseSupportMessageService()

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Header

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Contact Us")
                        .font(.largeTitle.bold())

                    Text(
                        "Messages sent by parents from the LunchBox app"
                    )
                    .foregroundStyle(.secondary)
                }

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
            .padding(24)

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

            } else if messages.isEmpty {

                ContentUnavailableView(
                    "No Messages",
                    systemImage: "envelope",
                    description: Text(
                        "Parent messages will appear here."
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
                        messages,
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
                .fontWeight(
                    message.status == "new"
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
            .font(.subheadline)
            .fontWeight(
                message.status == "new"
                    ? .semibold
                    : .regular
            )

            Text(message.message)
                .font(.caption)
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
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}


// MARK: - Message Detail

private struct MessageDetailView: View {

    let message: SupportMessage

    let onReplySent: () async -> Void

    @State private var replyText = ""
    @State private var isSending = false
    @State private var replyError: String?
    @State private var replySent = false

    private let service =
        FirebaseSupportMessageService()

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                Text(
                    message.subject.isEmpty
                        ? "Contact Us"
                        : message.subject
                )
                .font(.title.bold())

                Divider()

                // MARK: - Parent Information

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

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
                            value:
                                message.parentEmail
                        )
                    }

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

                Divider()

                // MARK: - Parent Message

                Text("MESSAGE")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text(message.message)
                    .font(.body)
                    .textSelection(.enabled)

                Divider()

                // MARK: - Reply

                Text("REPLY TO PARENT")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                TextEditor(
                    text: $replyText
                )
                .font(.body)
                .frame(
                    minHeight: 120
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
                }

                HStack {

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

                Spacer()
            }
            .padding(28)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .onChange(of: message.id) {

            replyText = ""
            replyError = nil
            replySent = false
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

            print(
                "📤 SUPPORT REPLY SENT:",
                message.id
            )

            await onReplySent()

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

    // MARK: - Detail Row

    private func detailRow(
        title: String,
        value: String
    ) -> some View {

        HStack(alignment: .top) {

            Text(title)
                .foregroundStyle(.secondary)
                .frame(
                    width: 80,
                    alignment: .leading
                )

            Text(value)
                .textSelection(.enabled)
        }
    }
}


#Preview {
    ContactUsView()
}
