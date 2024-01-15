//
//  msfinApp.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 08/01/2024.
//

import SwiftUI
import SwiftData

@main
struct msfinApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Category.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AccountsView()
        }
        .modelContainer(sharedModelContainer)
    }
}
