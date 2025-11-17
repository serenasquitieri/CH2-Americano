//
//  fin_passApp.swift
//  fin pass
//
//  Created by Serena Squitieri on 14/11/25.
//

import SwiftUI
import SwiftData

@main
struct Lucky_Locket: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Category.self)
    }
}
