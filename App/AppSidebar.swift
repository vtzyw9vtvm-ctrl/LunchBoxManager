import SwiftUI

struct AppSidebar: View {

    @Binding var selection: AppDestination

    var body: some View {

        List(AppDestination.allCases, selection: $selection) {

            destination in

            Label(
                destination.title,
                systemImage: destination.systemImage
            )
            .tag(destination)

        }
        .navigationTitle("School Lunch")

    }

}

#Preview {

    @Previewable
    @State var destination: AppDestination = .dashboard

    NavigationSplitView {

        AppSidebar(selection: $destination)

    } detail: {

        Text("Detail")

    }

}
