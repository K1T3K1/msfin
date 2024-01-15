//
//  PreviewModelContainer.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 10/01/2024.
//

import Foundation
import SwiftData

let PreviewModelContainer: ModelContainer = {
    let schema = Schema([
        Account.self,
        Transaction.self,
        Category.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
    }
}()
