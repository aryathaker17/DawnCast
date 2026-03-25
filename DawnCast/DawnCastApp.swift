//
//  DawnCastApp.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import SwiftUI
import SwiftData

@main
struct DawnCastApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([UserAccount.self, UserPreferences.self])
            let config = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If the store is incompatible (schema changed), delete and recreate
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            do {
                let schema = Schema([UserAccount.self, UserPreferences.self])
                let config = ModelConfiguration(schema: schema)
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
