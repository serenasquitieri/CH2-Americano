//
//  Password_appApp.swift
//  Password app
//
//  Created by Serena Squitieri on 10/11/25.
//

import SwiftUI
import SwiftData

struct Password_appApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // --- 2. AGGIUNGI IL CONTAINER! ---
        // Questo "inietta" il database in ContentView
        // e risolve l'errore.
        .modelContainer(for: PasswordEntry.self)
    }
}
