//
//  School_Lunch_ManagerApp.swift
//  School Lunch Manager
//

import SwiftUI

@main
struct School_Lunch_ManagerApp: App {

    var body: some Scene {

        WindowGroup("LunchBoxManager") {

            SidebarView()

        }

        .windowResizability(.contentSize)

        .defaultSize(
            width: 1400,
            height: 900
        )

    }

}
