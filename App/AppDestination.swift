import Foundation

enum AppDestination: String, CaseIterable, Identifiable {

    case dashboard
    case menu
    case schools
    case orders
    case labels
    case reports
    case settings

    var id: String { rawValue }

    var title: String {

        switch self {

        case .dashboard: return "Dashboard"
        case .menu: return "Menu"
        case .schools: return "Schools"
        case .orders: return "Orders"
        case .labels: return "Labels"
        case .reports: return "Reports"
        case .settings: return "Settings"

        }

    }

    var systemImage: String {

        switch self {

        case .dashboard: return "rectangle.grid.2x2"
        case .menu: return "fork.knife"
        case .schools: return "building.2"
        case .orders: return "cart"
        case .labels: return "tag"
        case .reports: return "doc.text"
        case .settings: return "gearshape"

        }

    }

}
