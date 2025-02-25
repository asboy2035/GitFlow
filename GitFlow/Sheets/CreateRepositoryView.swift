//
//  CreateRepositoryView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI
import Luminare

struct CreateRepositoryView: View {
    @EnvironmentObject var gitManager: GitRepositoryManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var repoPath = ""
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Repository")
                .font(.title2)
            
            LuminareSection {
                HStack {
                    LuminareTextField("Repository Path", text: $repoPath)
                    
                    Button(action: {
                        showingDirectoryPicker = true
                    }) {
                        Label("Browse", systemImage: "folder")
                    }
                    .frame(width: 100)
                }
                .frame(height: 35)
                
                HStack(spacing: 2) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Cancel", systemImage: "xmark")
                    }
                    
                    Button(action: {
                        gitManager.createRepository(at: repoPath)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Create", systemImage: "square.and.pencil")
                    }
                    .background(Color.accentColor.opacity(0.2))
                    .disabled(repoPath.isEmpty)
                }
                .frame(height: 35)
            }
            .buttonStyle(LuminareButtonStyle())
        }
        .frame(width: 300)
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                repoPath = selectedFile.path
            } catch {
                print("Error selecting directory: \(error.localizedDescription)")
            }
        }
    }
}
