//
//  AlignSeekApp.swift
//  AlignSeek
//

import SwiftUI

@main
struct AlignSeekApp: App {
    let persistenceController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
        }
    }
}
