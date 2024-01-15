//
//  Account.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 08/01/2024.
//

import Foundation
import SwiftData

enum AccountType: String, Codable {
    case Debit
    case Cash
    case Saving
    case Credit
}

@Model
final class Account {
    var id: UUID
    @Attribute(.unique) var name: String
    var type: AccountType
    var balance: Double

    init(name: String, type: AccountType, balance: Double) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.balance = balance
    }
}
