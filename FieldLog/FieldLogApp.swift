//
//  FieldLogApp.swift
//  FieldLog
//
//  Created by Wesley Klein on 9/11/26.
//

import SwiftUI
import SwiftData

@main
struct FieldLogApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer.fieldLog()
            try GearSeeder.seedIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
