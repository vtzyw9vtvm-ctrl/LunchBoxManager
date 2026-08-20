//
//  School_Lunch_ManagerApp.swift
//  School Lunch Manager
//

import SwiftUI
import FirebaseCore

@main
struct School_Lunch_ManagerApp: App {

    init() {
        FirebaseApp.configure()

        Task {
            await FirestoreService().testConnection()
        }
    }

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
