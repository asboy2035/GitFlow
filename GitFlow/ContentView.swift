//
//  ContentView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI
import Foundation
import Luminare

struct ContentView: View {
    @EnvironmentObject var gitManager: GitRepositoryManager
    @State private var showingCloneSheet = false
    @State private var showingCreateSheet = false
    @State private var showingOpenPanel = false
    @State private var showingStatusWindow = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack {
                if gitManager.repositories.isEmpty {
                    VStack(spacing: 20) {
                        Text("No Repositories")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(gitManager.repositories) { repo in
                        Label(repo.name, systemImage: "tray.full")
                            .onTapGesture {
                                gitManager.objectWillChange.send()  // Ensures UI updates
                                gitManager.currentRepository = repo
                            }
                            .padding(8)
                            .frame(minWidth: nil, maxWidth: .infinity, alignment: .leading)
                            .background(
                                gitManager.currentRepository?.id == repo.id ?
                                Color.accentColor.opacity(0.5) : Color.clear
                            ).ignoresSafeArea()
                            .cornerRadius(8)
                    }
                    .listStyle(.sidebar)
                }
                
                Spacer()
                Button("Show Status Log") {
                    showingStatusWindow.toggle()
                }
                .buttonStyle(LuminareButtonStyle())
                .frame(height: 30)
            }
            .padding(.top, 40)
            .frame(minWidth: 250, maxWidth: 300)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        showingOpenPanel = true
                    }) {
                        Label("Open", systemImage: "document")
                    }
                }
                
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        showingCloneSheet = true
                    }) {
                        Label("Clone", systemImage: "arrow.down.circle")
                    }
                }
                
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Label("Create", systemImage: "square.and.pencil")
                    }
                }
            }
            
            Divider()
            ZStack {
                if let repo = gitManager.currentRepository {
                    RepositoryView(repository: repo)
                } else {
                    Text("Select or open a repository to begin")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Progress overlay for current repository operations
                if let repo = gitManager.currentRepository, repo.isOperationInProgress {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(repo.currentOperation)
                            .padding()
                            .background(.background.opacity(0.8))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
                }
            }
        }
        .navigationTitle("GitFlow")
        .onAppear() {
            gitManager.loadSavedRepositories()
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow)).ignoresSafeArea()
        .sheet(isPresented: $showingCloneSheet) {
            CloneRepositoryView()
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateRepositoryView()
        }
        .sheet(isPresented: $showingStatusWindow) {
            StatusLogView()
                .environmentObject(gitManager)
        }
        .fileImporter(
            isPresented: $showingOpenPanel,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                let path = selectedFile.path
                gitManager.openRepository(at: path)
            } catch {
                print("Error selecting directory: \(error.localizedDescription)")
            }
        }
        .alert(item: alertBinding()) { alertInfo in
            Alert(
                title: Text("Error"),
                message: Text(alertInfo.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func alertBinding() -> Binding<AlertInfo?> {
        return Binding<AlertInfo?>(
            get: {
                guard let errorMessage = gitManager.errorMessage else { return nil }
                return AlertInfo(id: UUID(), message: errorMessage)
            },
            set: { _ in gitManager.errorMessage = nil }
        )
    }
}


struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
