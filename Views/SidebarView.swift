import SwiftUI
import AppKit
import FirebaseFirestore

struct SidebarView: View {

    enum Destination: Hashable {
        case dashboard
        case menu
        case modifiers
        case schools
        case schoolOrders
        case contactUs
        case cafe
        case inventory
        case reports
        case settings
    }

    @State private var selection: Destination? = .dashboard

    @State private var ordersManager = OrdersManager()

    @State private var unreadSupportCount = 0

    @State private var supportListener:
        ListenerRegistration?

    // Prevents the sound playing when the app first
    // loads the existing unread message count.
    @State private var hasReceivedInitialSupportCount = false

    private let supportMessageService =
        FirebaseSupportMessageService()

    var body: some View {

        NavigationSplitView {

            List(selection: $selection) {

                Section("Home") {

                    Label(
                        "Dashboard",
                        systemImage: "house"
                    )
                    .tag(Destination.dashboard)
                }

                Section("Menu") {

                    Label(
                        "Menu",
                        systemImage: "fork.knife"
                    )
                    .tag(Destination.menu)

                    Label(
                        "Modifier Groups",
                        systemImage: "slider.horizontal.3"
                    )
                    .tag(Destination.modifiers)

                    Label(
                        "Schools",
                        systemImage: "building.2"
                    )
                    .tag(Destination.schools)
                }

                Section("Operations") {

                    Label(
                        "School Orders",
                        systemImage: "graduationcap"
                    )
                    .tag(Destination.schoolOrders)

                    // MARK: - Contact Us

                    HStack {

                        Label(
                            "Contact Us",
                            systemImage: "envelope"
                        )

                        Spacer()

                        if unreadSupportCount > 0 {

                            Text("\(unreadSupportCount)")
                                .font(
                                    .system(
                                        size: 11,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.red)
                                )
                        }
                    }
                    .tag(Destination.contactUs)

                    Label(
                        "Cafe",
                        systemImage: "cup.and.saucer"
                    )
                    .tag(Destination.cafe)

                    Label(
                        "Inventory",
                        systemImage: "shippingbox"
                    )
                    .tag(Destination.inventory)
                }

                Section("Business") {

                    Label(
                        "Reports",
                        systemImage: "chart.bar"
                    )
                    .tag(Destination.reports)

                    Label(
                        "Settings",
                        systemImage: "gearshape"
                    )
                    .tag(Destination.settings)
                }
            }
            .navigationTitle("LunchBoxManager")

        } detail: {

            switch selection {

            case .dashboard:

                DashboardView(
                    orders: ordersManager.orders
                )

            case .menu:

                MenuWorkspaceView()

            case .modifiers:

                ModifierWorkspaceView()

            case .schools:

                SchoolsWorkspaceView()

            case .schoolOrders:

                OrdersView(
                    orders: ordersManager.orders,
                    onOrdersChanged: { updatedOrders in

                        ordersManager.replaceOrders(
                            with: updatedOrders
                        )
                    }
                )

            case .contactUs:

                ContactUsView()

            case .cafe:

                Text("Cafe")

            case .inventory:

                Text("Inventory")

            case .reports:

                Text("Reports")

            case .settings:

                SettingsView()

            case nil:

                Text("Select an option")
            }
        }

        // MARK: - Live Support Message Listener

        .onAppear {
            startSupportMessageListener()
        }

        .onDisappear {

            supportListener?.remove()
            supportListener = nil
        }
    }

    // MARK: - Start Live Listener

    private func startSupportMessageListener() {

        supportListener?.remove()

        hasReceivedInitialSupportCount = false

        supportListener =
            supportMessageService
                .listenForUnreadCount { count in

                    let previousCount =
                        unreadSupportCount

                    unreadSupportCount = count

                    // Don't make a sound for unread
                    // messages that already existed when
                    // LunchBoxManager was opened.
                    if hasReceivedInitialSupportCount {

                        // Only sound when the number of
                        // unread messages increases.
                        if count > previousCount {

                            playNewMessageSound()
                        }

                    } else {

                        hasReceivedInitialSupportCount = true
                    }

                    print(
                        "📩 LIVE UNREAD SUPPORT MESSAGES:",
                        count
                    )
                }
    }

    // MARK: - New Message Sound

    private func playNewMessageSound() {

        NSSound(named: "Glass")?.play()

        print("🔔 NEW SUPPORT MESSAGE SOUND")
    }
}

#Preview {
    SidebarView()
}
