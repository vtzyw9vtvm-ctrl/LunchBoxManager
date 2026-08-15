import SwiftUI

struct SidebarView: View {

    enum Destination: Hashable {

        case dashboard
        case menu
        case modifiers
        case schools
        case schoolOrders
        case cafe
        case inventory
        case reports
        case settings

    }

    @State private var selection: Destination? = .menu

    var body: some View {

        NavigationSplitView {

            List(selection: $selection) {

                Section("Home") {

                    Label("Dashboard", systemImage: "house")
                        .tag(Destination.dashboard)

                }

                Section("Menu") {

                    Label("Menu", systemImage: "fork.knife")
                        .tag(Destination.menu)

                    Label("Modifier Groups", systemImage: "slider.horizontal.3")
                        .tag(Destination.modifiers)
                    
                    Label("Schools", systemImage: "building.2")
                        .tag(Destination.schools)

                }

                Section("Operations") {

                    Label("School Orders", systemImage: "graduationcap")
                        .tag(Destination.schoolOrders)

                    Label("Cafe", systemImage: "cup.and.saucer")
                        .tag(Destination.cafe)

                    Label("Inventory", systemImage: "shippingbox")
                        .tag(Destination.inventory)

                }

                Section("Business") {

                    Label("Reports", systemImage: "chart.bar")

                        .tag(Destination.reports)

                    Label("Settings", systemImage: "gearshape")

                        .tag(Destination.settings)

                }

            }
            .navigationTitle("LunchBoxManager")

        } detail: {

            switch selection {

            case .dashboard:
                Text("Dashboard")

            case .menu:
                MenuWorkspaceView()

            case .modifiers:
                ModifierWorkspaceView()
                
            case .schools:
                SchoolsWorkspaceView()

            case .schoolOrders:
                Text("School Orders")

            case .cafe:
                Text("Cafe")

            case .inventory:
                Text("Inventory")

            case .reports:
                Text("Reports")

            case .settings:
                Text("Settings")

            case nil:
                Text("Select an option")

            }

        }

    }

}

#Preview {

    SidebarView()

}
