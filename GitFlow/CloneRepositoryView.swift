//
//  CloneRepositoryView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI

struct CloneRepositoryView: View {
    @EnvironmentObject var gitManager: GitRepositoryManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var repoURL = ""
    @State private var destinationPath = ""
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Clone Repository")
                .font(.title)
            
            TextField("Repository URL", text: $repoURL)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                TextField("Destination Path", text: $destinationPath)
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
                
                Button("Clone") {
                    gitManager.cloneRepository(url: repoURL, destinationPath: destinationPath)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(repoURL.isEmpty || destinationPath.isEmpty)
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
                destinationPath = selectedFile.path
            } catch {
                print("Error selecting directory: \(error.localizedDescription)")
            }
        }
    }
}
