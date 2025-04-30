//
//  Finder_by_RelocaneApp.swift
//  Finder by Relocane
//
//  Created by: RELOCANE LLC on 1/27/25.
//

import SwiftUI

@main
struct RelocaneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BLEmanager())
                .environmentObject(Beep())
        }
    }
}
