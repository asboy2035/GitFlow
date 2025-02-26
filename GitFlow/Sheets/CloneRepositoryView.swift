//
//  CloneRepositoryView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI
import Luminare

struct CloneRepositoryView: View {
    @ObservedObject var gitManager: GitRepositoryManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var repoURL = ""
    @State private var destinationPath = ""
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Clone Repository")
                .font(.title2)
            
            LuminareSection {
                LuminareTextField("Repository URL", text: $repoURL)
                
                HStack {
                    LuminareTextField("Destination Path", text: $destinationPath)
                    
                    Button(action: {
                        showingDirectoryPicker = true
                    }) {
                        Label("Browse", systemImage: "folder")
                    }
                    .frame(width: 100)
                }
                
                HStack(spacing: 2) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Cancel", systemImage: "xmark")
                    }
                    
                    Button(action: {
                        gitManager.cloneRepository(url: repoURL, destinationPath: destinationPath)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Clone", systemImage: "arrow.down.circle")
                    }
                    .background(Color.accentColor.opacity(0.2))
                    .disabled(repoURL.isEmpty || destinationPath.isEmpty)
                }
            }
        }
        .frame(width: 300)
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                destinationPath = selectedFile.path
            } catch {
                print("Error selecting directory: \(error.localizedDescription)")
            }
        }
    }
}
