//
//  Item.swift
//  FieldLog
//
//  Created by Wesley Klein on 9/11/26.
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
