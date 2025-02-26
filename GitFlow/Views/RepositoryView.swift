//
//  RepositoryView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import AppKit
import SwiftUI
import Luminare

// -MARK: Main
struct RepositoryView: View {
    @ObservedObject var repository: GitRepository
    @State private var selectedTab = 0
    @State private var commitMessage = ""
    @State private var selectedFileForDiff: GitFileChange?
    @State private var showingNewBranchSheet = false
    @State private var newBranchName = ""
    @State private var showingStashSheet = false
    @State private var stashMessage = ""
    
    var body: some View {
        VStack(spacing: 12) {
            RepositoryHeaderView(repository: repository)
            CommitActionsView(commitMessage: $commitMessage, showingNewBranchSheet: $showingNewBranchSheet, repository: repository)
            RepositoryTabView(selectedTab: $selectedTab, repository: repository, selectedFileForDiff: $selectedFileForDiff)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    repository.pull()
                    repository.refreshStatus()
                }) {
                    Label("Pull", systemImage: "arrowshape.turn.up.left")
                }
                .help("Pull")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    repository.push()
                    repository.refreshStatus()
                }) {
                    Label("Push", systemImage: "arrowshape.turn.up.right")
                }
                .help("Push")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showingStashSheet = true
                }) {
                    Label("Stash", systemImage: "square.and.arrow.up")
                }
                .help("Stash")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    repository.refreshStatus()
                }) {
                    Label("Refresh", systemImage: "arrow.trianglehead.2.clockwise")
                }
                .help("Refresh")
            }
        }
        .luminareModal(isPresented: $showingNewBranchSheet, closeOnDefocus: true) {
            NewBranchSheetView(newBranchName: $newBranchName, showingNewBranchSheet: $showingNewBranchSheet, repository: repository)
        }
        .luminareModal(isPresented: $showingStashSheet, closeOnDefocus: true) {
            StashSheetView(stashMessage: $stashMessage, showingStashSheet: $showingStashSheet, repository: repository)
        }
    }
}

// -MARK: Header
struct RepositoryHeaderView: View {
    var repository: GitRepository
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(repository.name)
                    .font(.title)
                Text(repository.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: nil, maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 2) {
                Image("branch-fork")
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(repository.currentBranch)
            }
            .frame(minWidth: nil, maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

// -MARK: Commit Actions
struct CommitActionsView: View {
    @Binding var commitMessage: String
    @Binding var showingNewBranchSheet: Bool
    var repository: GitRepository
    
    var body: some View {
        LuminareSection("Commit") {
            HStack {
                LuminareTextField("Commit message", text: $commitMessage)
                
                HStack(spacing: 2) {
                    Button(action: {
                        if !commitMessage.isEmpty {
                            repository.commit(message: commitMessage)
                            commitMessage = ""
                            repository.refreshStatus()
                        }
                    }) {
                        Label("Commit", systemImage: "paperplane")
                    }
                    .background(Color.accentColor.opacity(0.2))
                    .disabled(commitMessage.isEmpty)
                    
                    Button(action: {
                        repository.stageAllFiles()
                        repository.refreshStatus()
                    }) {
                        Label("Stage All", systemImage: "checkmark")
                    }
                    
                    Button(action: {
                        showingNewBranchSheet = true
                    }) {
                        Label("New Branch", systemImage: "arrow.trianglehead.branch")
                    }
                }
                .buttonStyle(LuminareButtonStyle())
            }
            .frame(height: 35)
        }
        .padding(.horizontal)
    }
}

// -MARK: Tab Views
struct RepositoryTabView: View {
    @Binding var selectedTab: Int
    var repository: GitRepository
    @Binding var selectedFileForDiff: GitFileChange?
    @State private var currentTab: String = "Changes"
    
    var body: some View {
        VStack {
            LuminareSection("Details") {
                HStack(spacing: 2) {
                    Button(action: {
                        currentTab = "Changes"
                    }) {
                        Label("Changes", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Button( action: {
                        currentTab = "Commits"
                    }) {
                        Label("Commits", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                    
                    Button( action: {
                        currentTab = "Branches"
                    }) {
                        Label("Branches", systemImage: "arrow.trianglehead.branch")
                    }
                    
                    Button( action: {
                        currentTab = "Remotes"
                    }) {
                        Label("Remotes", systemImage: "network")
                    }
                    
                    Button( action: {
                        currentTab = "Stashes"
                    }) {
                        Label("Stashes", systemImage: "shippingbox")
                    }
                }
                .frame(height: 35)
                .buttonStyle(LuminareButtonStyle())
                
                VStack {
                    switch (currentTab) {
                    case "Commits":
                        CommitsView(repository: repository)
                    case "Branches":
                        BranchesTabView(repository: repository)
                    case "Remotes":
                        RemotesTabView(repository: repository)
                    case "Stashes":
                        StashesTabView(repository: repository)
                    default:
                        ChangesTabView(repository: repository, selectedFileForDiff: $selectedFileForDiff)
                    }
                }
                .padding(8)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding()
    }
}

struct ChangesTabView: View {
    @ObservedObject var repository: GitRepository
    @Binding var selectedFileForDiff: GitFileChange?

    var body: some View {
        VStack {
            if let fileForDiff = selectedFileForDiff {
                DiffView(repository: repository, selectedFile: fileForDiff, onClose: {
                    selectedFileForDiff = nil
                })
            } else {
                ScrollView {
                    LuminareSection("Staged Changes") {
                        ForEach(repository.changes.filter { $0.staged }) { change in
                            FileChangeRow(change: change) {
                                repository.unstageFile(path: change.path)
                                repository.refreshStatus()
                            } viewDiff: {
                                selectedFileForDiff = change
                            } discard: {
                                repository.discardChanges(file: change.path)
                                repository.refreshStatus()
                            }
                            .padding(4)
                        }

                        if repository.changes.filter({ $0.staged }).isEmpty {
                            Text("No staged changes")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }

                    LuminareSection("Unstaged Changes") {
                        ForEach(repository.changes.filter { !$0.staged }) { change in
                            FileChangeRow(change: change) {
                                repository.stageFile(path: change.path)
                                repository.refreshStatus()
                            } viewDiff: {
                                selectedFileForDiff = change
                            } discard: {
                                repository.discardChanges(file: change.path)
                                repository.refreshStatus()
                            }
                        }

                        if repository.changes.filter({ !$0.staged }).isEmpty {
                            Text("No unstaged changes")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
            }
        }
    }
}

struct CommitsView: View {
    @ObservedObject var repository: GitRepository

    // Call this only once when the view appears
    @State private var isFetchingCommits = false
    
    var body: some View {
        List(repository.commits) { commit in
            HStack {
                VStack(alignment: .leading) {
                    Text(commit.message)
                    Text("By \(commit.author) on \(commit.date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.setString(commit.hash, forType: .string)
                }) {
                    Label("Copy Hash", systemImage: "doc.on.doc")
                        .foregroundStyle(.primary)
                        .padding(.vertical, 6)
                }
                .buttonStyle(LuminareCompactButtonStyle())
                .frame(width: 150)
            }
        }
        .onAppear {
            // Make sure it only fetches commits once
            if !isFetchingCommits {
                repository.fetchCommits()
                isFetchingCommits = true
            }
        }
    }
}

struct BranchesTabView: View {
    var repository: GitRepository

    var body: some View {
        ScrollView {
            LuminareSection("Local Branches") {
                ForEach(repository.branches.filter { !$0.isRemote }) { branch in
                    HStack {
                        Text(branch.name)
                            .fontWeight(branch.isCurrent ? .bold : .regular)

                        if branch.isCurrent {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }

                        Spacer()

                        if !branch.isCurrent {
                            Button(action: {
                                repository.checkout(branch: branch.name)
                                repository.refreshStatus()
                            }) {
                                Label("Checkout", systemImage: "magnifyingglass")
                            }
                            .frame(width: 120)
                            .buttonStyle(LuminareCompactButtonStyle())
                        }
                    }
                    .padding(4)
                }
            }

            LuminareSection("Remote Branches") {
                ForEach(repository.branches.filter { $0.isRemote }) { branch in
                    HStack {
                        Text(branch.name)

                        Spacer()

                        Button(action: {
                            repository.checkout(branch: branch.name)
                            repository.refreshStatus()
                        }) {
                            Label("Checkout", systemImage: "magnifyingglass")
                        }
                        .frame(width: 120)
                        .buttonStyle(LuminareCompactButtonStyle())
                    }
                    .padding(4)
                }
            }
        }
    }
}

struct RemotesTabView: View {
    var repository: GitRepository

    var body: some View {
        VStack {
            List {
                ForEach(repository.remotes) { remote in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(remote.name)
                                .fontWeight(.bold)
                            Text(remote.url)
                                .font(.caption)
                            Text(remote.type)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            repository.pull()
                            repository.refreshStatus()
                        }) {
                            Image(systemName: "arrowshape.turn.up.left")
                        }
                        .help("Pull")
                        .frame(width: 35, height: 35)

                        Button(action: {
                            repository.push(remote: remote.name)
                            repository.refreshStatus()
                        }) {
                            Image(systemName: "arrowshape.turn.up.right")
                        }
                        .help("Push")
                        .frame(width: 35, height: 35)
                    }
                    .buttonStyle(LuminareCompactButtonStyle())
                }
            }
        }
    }
}

struct StashesTabView: View {
    var repository: GitRepository

    var body: some View {
        VStack {
            List {
                ForEach(repository.stashes) { stash in
                    HStack {
                        Text("Stash \(stash.index): \(stash.description)")

                        Spacer()

                        Button("Apply") {
                            repository.applyStash(index: stash.index)
                            repository.refreshStatus()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if repository.stashes.isEmpty {
                    Text("No stashes found")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

// -MARK: Diff
struct DiffView: View {
    var repository: GitRepository
    var selectedFile: GitFileChange
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Diff: \(selectedFile.path)")
                    .font(.headline)
                
                Spacer()
                
                LuminareSection {
                    HStack(spacing: 2) {
                        Button(action: {
                            openInFileMerge()
                        }) {
                            Label("Open in FileMerge", systemImage: "text.page.badge.magnifyingglass")
                        }
                        .frame(width: 200)
                        .disabled(true)
                        
                        Button(action: onClose) {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                    .buttonStyle(LuminareButtonStyle())
                }
                .frame(width: 300, height: 35)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    let diffLines = repository.getFileDiff(file: selectedFile.path).components(separatedBy: "\n")
                    
                    ForEach(diffLines, id: \.self) { line in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                            .padding(.vertical, 1)
                            .background(getBackgroundColor(for: line))
                    }
                }
            }
            .frame(minWidth: nil, maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    private func getBackgroundColor(for line: String) -> Color {
        if line.hasPrefix("+") {
            return Color.green.opacity(0.3) // Highlight additions
        } else if line.hasPrefix("-") {
            return Color.red.opacity(0.3) // Highlight deletions
        } else {
            return Color.clear
        }
    }
    
    private func openInFileMerge() {
        let fileURL = URL(fileURLWithPath: repository.path).appendingPathComponent(selectedFile.path)
        let task = Process()
        task.launchPath = "/usr/bin/opendiff" // FileMerge command
        task.arguments = [fileURL.path]
        
        do {
            try task.run()
        } catch {
            print("Failed to open FileMerge: \(error)")
        }
    }
}

// -MARK: New Branch
struct NewBranchSheetView: View {
    @Binding var newBranchName: String
    @Binding var showingNewBranchSheet: Bool
    var repository: GitRepository
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Branch")
                .font(.title2)
            
            LuminareSection {
                LuminareTextField("Branch name", text: $newBranchName)
                
                HStack(spacing: 2) {
                    Button(action: {
                        showingNewBranchSheet = false
                        newBranchName = ""
                    }) {
                        Label("Cancel", systemImage: "xmark")
                    }
                    
                    Button(action: {
                        if !newBranchName.isEmpty {
                            repository.createBranch(name: newBranchName)
                            repository.refreshStatus()
                            showingNewBranchSheet = false
                            newBranchName = ""
                        }
                    }) {
                        Label("Create", systemImage: "square.and.pencil")
                    }
                    .background(Color.accentColor.opacity(0.2))
                    .disabled(newBranchName.isEmpty)
                }
                .buttonStyle(LuminareButtonStyle())
                .frame(height: 35)
            }
        }
        .frame(width: 300)
    }
}

// -MARK: Stash
struct StashSheetView: View {
    @Binding var stashMessage: String
    @Binding var showingStashSheet: Bool
    var repository: GitRepository
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Stash")
                .font(.title2)
            
            LuminareSection {
                LuminareTextField("Stash message (optional)", text: $stashMessage)
                
                HStack(spacing: 2) {
                    Button(action: {
                        showingStashSheet = false
                        stashMessage = ""
                    }) {
                        Label("Cancel", systemImage: "xmark")
                    }
                    
                    Button(action: {
                        if stashMessage.isEmpty {
                            repository.createStash()
                        } else {
                            repository.createStash(message: stashMessage)
                        }
                        repository.refreshStatus()
                        showingStashSheet = false
                        stashMessage = ""
                    }) {
                        Label("Create Stash", systemImage: "square.and.pencil")
                    }
                    .background(Color.accentColor.opacity(0.2))
                }
                .buttonStyle(LuminareButtonStyle())
                .frame(height: 35)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
