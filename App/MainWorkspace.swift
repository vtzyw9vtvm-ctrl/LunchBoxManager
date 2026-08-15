import SwiftUI

struct MainWorkspace: View {

    @State private var destination: AppDestination = .dashboard

    var body: some View {

        NavigationSplitView {

            AppSidebar(
                selection: $destination
            )

        } detail: {

            switch destination {

            case .dashboard:

                ContentUnavailableView(
                    "Dashboard",
                    systemImage: "rectangle.grid.2x2"
                )

            case .menu:

                MenuWorkspaceView()

            case .schools:

                SchoolsWorkspaceView()

            case .orders:

                ContentUnavailableView(
                    "Orders",
                    systemImage: "cart"
                )

            case .labels:

                ContentUnavailableView(
                    "Labels",
                    systemImage: "tag"
                )

            case .reports:

                ContentUnavailableView(
                    "Reports",
                    systemImage: "doc.text"
                )

            case .settings:

                ContentUnavailableView(
                    "Settings",
                    systemImage: "gearshape"
                )

            }

        }

    }

}

#Preview {

    MainWorkspace()

}
