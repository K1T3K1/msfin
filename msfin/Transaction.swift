//
//  Transaction.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 08/01/2024.
//

import Foundation
import SwiftData

@Model
class Transaction {
    var id: UUID
    var timestamp: Date
    var value: Double
    @Relationship(deleteRule: .noAction)
    var account: Account
    var name: String
    var category: Optional<Category>
    
    init(timestamp: Date, value: Double, account: Account, name: String, category: Optional<Category>) {
        self.id = UUID()
        self.timestamp = timestamp
        self.value = value
        self.account = account
        self.name = name
        self.category = category
    }
}


