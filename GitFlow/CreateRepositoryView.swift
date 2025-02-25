//
//  CreateRepositoryView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI

struct CreateRepositoryView: View {
    @EnvironmentObject var gitManager: GitRepositoryManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var repoPath = ""
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Repository")
                .font(.title)
            
            HStack {
                TextField("Repository Path", text: $repoPath)
                    .textFieldStyle(.roundedBorder)
                
                Button("Browse") {
                    showingDirectoryPicker = true
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Create") {
                    gitManager.createRepository(at: repoPath)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(repoPath.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
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
