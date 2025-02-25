//
//  GitFlowApp.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI

@main
struct GitFlowApp: App {
    var body: some Scene {
        Window("ContentView", id: "main") {
            ContentView()
                .frame(minWidth: 1000, minHeight: 600)
                .environmentObject(GitRepositoryManager())
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        // Set window titlebar transparency and style
                        window.titlebarAppearsTransparent = true
                        window.isOpaque = false
                        window.backgroundColor = .clear // Set the background color to clear
                        
                        window.styleMask.insert(.fullSizeContentView)
                        window.tabbingMode = .disallowed
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}
