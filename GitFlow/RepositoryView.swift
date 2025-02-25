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
            
            if let selectedFile = selectedFileForDiff {
                DiffView(repository: repository, selectedFile: selectedFile)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    repository.pull()
                    repository.refreshStatus()
                }) {
                    Label("Pull", systemImage: "arrowshape.turn.up.left")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    repository.push()
                    repository.refreshStatus()
                }) {
                    Label("Push", systemImage: "arrowshape.turn.up.right")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showingStashSheet = true
                }) {
                    Label("Stash", systemImage: "square.and.arrow.up")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    repository.refreshStatus()
                }) {
                    Label("Refresh", systemImage: "arrow.trianglehead.2.clockwise")
                }
            }
        }
        .sheet(isPresented: $showingNewBranchSheet) {
            NewBranchSheetView(newBranchName: $newBranchName, showingNewBranchSheet: $showingNewBranchSheet, repository: repository)
        }
        .sheet(isPresented: $showingStashSheet) {
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
                    Button("Commit") {
                        if !commitMessage.isEmpty {
                            repository.commit(message: commitMessage)
                            commitMessage = ""
                            repository.refreshStatus()
                        }
                    }
                    .background(Color.accentColor.opacity(0.2))
                    .disabled(commitMessage.isEmpty)
                    
                    Button("Stage All") {
                        repository.stageAllFiles()
                        repository.refreshStatus()
                    }
                    
                    Button("New Branch") {
                        showingNewBranchSheet = true
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
        }
        .listStyle(.sidebar)
        .padding()
    }
}

struct ChangesTabView: View {
    @ObservedObject var repository: GitRepository
    @Binding var selectedFileForDiff: GitFileChange?

    var body: some View {
        VStack {
            List {
                Section(header: Text("Staged Changes")) {
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
                    }

                    if repository.changes.filter({ $0.staged }).isEmpty {
                        Text("No staged changes")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }

                Section(header: Text("Unstaged Changes")) {
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
                        .padding(.vertical, 6)
                }
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
        VStack {
            List {
                Section(header: Text("Local Branches")) {
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
                                Button("Checkout") {
                                    repository.checkout(branch: branch.name)
                                    repository.refreshStatus()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                Section(header: Text("Remote Branches")) {
                    ForEach(repository.branches.filter { $0.isRemote }) { branch in
                        HStack {
                            Text(branch.name)

                            Spacer()

                            Button("Checkout") {
                                repository.checkout(branch: branch.name)
                                repository.refreshStatus()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
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

                        Button("Pull") {
                            repository.pull()
                            repository.refreshStatus()
                        }
                        .buttonStyle(.bordered)

                        Button("Push") {
                            repository.push(remote: remote.name)
                            repository.refreshStatus()
                        }
                        .buttonStyle(.bordered)
                    }
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
    
    var body: some View {
        VStack {
            HStack {
                Text("Diff: \(selectedFile.path)")
                    .font(.headline)
                
                Spacer()
                
                Button("Close") {
                    // Handle close action
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            ScrollView {
                Text(repository.getFileDiff(file: selectedFile.path))
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .frame(height: 300)
            .background(Color.black.opacity(0.03))
            .cornerRadius(8)
            .padding()
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
                .font(.headline)
            
            TextField("Branch name", text: $newBranchName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    showingNewBranchSheet = false
                    newBranchName = ""
                }
                .buttonStyle(.bordered)
                
                Button("Create") {
                    if !newBranchName.isEmpty {
                        repository.createBranch(name: newBranchName)
                        repository.refreshStatus()
                        showingNewBranchSheet = false
                        newBranchName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newBranchName.isEmpty)
            }
        }
        .padding()
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
                .font(.headline)
            
            TextField("Stash message (optional)", text: $stashMessage)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    showingStashSheet = false
                    stashMessage = ""
                }
                .buttonStyle(.bordered)
                
                Button("Create Stash") {
                    if stashMessage.isEmpty {
                        repository.createStash()
                    } else {
                        repository.createStash(message: stashMessage)
                    }
                    repository.refreshStatus()
                    showingStashSheet = false
                    stashMessage = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
