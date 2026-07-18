//
//  Item.swift
//  School Lunch Manager
//
//  Created by Marilyn Merritt on 18/7/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
