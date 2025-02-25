//
//  Models.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import Foundation

class GitRepositoryManager: ObservableObject {
    @Published var currentRepository: GitRepository? {
        didSet {
            refreshCurrentRepository()
        }
    }
    @Published var repositories: [GitRepository] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var statusMessages: [StatusMessage] = []
    
    func openRepository(at path: String) {
        isLoading = true
        defer { isLoading = false }
        
        addStatusMessage("Opening repository at \(path)...")
        
        // Check if repository already exists in our list
        if let existingRepo = repositories.first(where: { $0.path == path }) {
            currentRepository = existingRepo
            refreshCurrentRepository()
            addStatusMessage("Repository opened successfully", isSuccess: true)
            return
        }
        
        // Verify it's a git repository
        guard isGitRepository(path: path) else {
            errorMessage = "Not a valid Git repository"
            addStatusMessage("Failed to open repository: Not a valid Git repository", isError: true)
            return
        }
        
        let newRepo = GitRepository(path: path)
        newRepo.statusCallback = { [weak self] message, isSuccess, isError in
            self?.addStatusMessage(message, isSuccess: isSuccess, isError: isError)
        }
        repositories.append(newRepo)
        currentRepository = newRepo
        refreshCurrentRepository()
        
        // Save to user defaults
        saveRepositoryList()
        
        addStatusMessage("Repository opened successfully", isSuccess: true)
    }
    
    func cloneRepository(url: String, destinationPath: String) {
        isLoading = true
        
        addStatusMessage("Cloning repository from \(url) to \(destinationPath)...")
        
        // Create a process for git clone
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["clone", url, destinationPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                // Successfully cloned
                addStatusMessage("Repository cloned successfully", isSuccess: true)
                openRepository(at: destinationPath)
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                errorMessage = "Failed to clone: \(output)"
                addStatusMessage("Failed to clone repository: \(output)", isError: true)
            }
        } catch {
            errorMessage = "Error executing git: \(error.localizedDescription)"
            addStatusMessage("Error executing git: \(error.localizedDescription)", isError: true)
        }
        
        isLoading = false
    }
    
    func createRepository(at path: String) {
        isLoading = true
        
        addStatusMessage("Creating new repository at \(path)...")
        
        // Create directory if it doesn't exist
        let fileManager = FileManager.default
        do {
            if !fileManager.fileExists(atPath: path) {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            }
            
            // Initialize git repository
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["-C", path, "init"]
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                addStatusMessage("Repository created successfully", isSuccess: true)
                openRepository(at: path)
            } else {
                errorMessage = "Failed to initialize repository"
                addStatusMessage("Failed to initialize repository", isError: true)
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            addStatusMessage("Error: \(error.localizedDescription)", isError: true)
        }
        
        isLoading = false
    }
    
    func refreshCurrentRepository() {
        currentRepository?.refreshStatus()
        currentRepository?.fetchCommits()
    }
    
    func addStatusMessage(_ message: String, isSuccess: Bool = false, isError: Bool = false) {
        let statusMessage = StatusMessage(message: message, isSuccess: isSuccess, isError: isError)
        DispatchQueue.main.async {
            self.statusMessages.append(statusMessage)
            
            // Keep only the last 20 messages
            if self.statusMessages.count > 20 {
                self.statusMessages.removeFirst(self.statusMessages.count - 20)
            }
        }
    }
    
    private func isGitRepository(path: String) -> Bool {
        let gitDirPath = "\(path)/.git"
        return FileManager.default.fileExists(atPath: gitDirPath)
    }
    
    private func saveRepositoryList() {
        let paths = repositories.map { $0.path }
        UserDefaults.standard.set(paths, forKey: "savedRepositories")
    }
    
    func loadSavedRepositories() {
        if let paths = UserDefaults.standard.stringArray(forKey: "savedRepositories") {
            for path in paths {
                if isGitRepository(path: path) {
                    let repo = GitRepository(path: path)
                    repo.statusCallback = { [weak self] message, isSuccess, isError in
                        self?.addStatusMessage(message, isSuccess: isSuccess, isError: isError)
                    }
                    repositories.append(repo)
                }
            }
        }
    }
    
    func clearStatusMessages() {
        statusMessages.removeAll()
    }
}

class GitRepository: ObservableObject, Identifiable {
    let id = UUID()
    let path: String
    
    var statusCallback: ((String, Bool, Bool) -> Void)?
    
    @Published var name: String
    @Published var branches: [GitBranch] = []
    @Published var currentBranch: String = ""
    @Published var commits: [Commit] = []
    @Published var remotes: [GitRemote] = []
    @Published var changes: [GitFileChange] = []
    @Published var stashes: [GitStash] = []
    @Published var isOperationInProgress: Bool = false
    @Published var currentOperation: String = ""
    
    init(path: String) {
        self.path = path
        self.name = URL(fileURLWithPath: path).lastPathComponent
        startWatchingChanges() // Start auto-refresh
        refreshStatus()
    }
    
    deinit {
        stopWatchingChanges()
    }
    
    func refreshStatus() {
        sendStatusMessage("Refreshing repository status...")
        refreshBranches()
        refreshCurrentBranch()
        refreshRemotes()
        refreshChanges()
        refreshStashes()
        sendStatusMessage("Repository status refreshed", isSuccess: true)
    }
    
    func refreshBranches() {
        branches = executeGitCommand(arguments: ["branch", "--list", "--all"])
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { branch -> GitBranch in
                let isCurrent = branch.hasPrefix("*")
                let trimmedName = branch.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "* ", with: "")
                
                let isRemote = trimmedName.contains("remotes/")
                let displayName = isRemote ? trimmedName.components(separatedBy: "remotes/").last ?? trimmedName : trimmedName
                
                return GitBranch(name: displayName, isRemote: isRemote, isCurrent: isCurrent)
            }
    }
    
    func refreshCurrentBranch() {
        currentBranch = executeGitCommand(arguments: ["rev-parse", "--abbrev-ref", "HEAD"]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func refreshRemotes() {
        let remoteOutput = executeGitCommand(arguments: ["remote", "-v"])
        let lines = remoteOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        // Group by remote name to avoid duplicates
        var remoteMap: [String: GitRemote] = [:]
        
        for line in lines {
            let components = line.components(separatedBy: "\t")
            guard components.count >= 2 else { continue }
            
            let name = components[0]
            let urlAndType = components[1]
            
            // Extract URL and type (e.g., "(fetch)" or "(push)")
            let urlTypeParts = urlAndType.components(separatedBy: " ")
            guard urlTypeParts.count >= 1 else { continue }
            
            let url = urlTypeParts[0]
            let type = urlTypeParts.count > 1 ? urlTypeParts[1].trimmingCharacters(in: CharacterSet(charactersIn: "()")) : ""
            
            // Only store one entry per remote name (prefer fetch)
            if remoteMap[name] == nil || type == "fetch" {
                remoteMap[name] = GitRemote(name: name, url: url, type: type)
            }
        }
        
        // Convert map to array
        remotes = Array(remoteMap.values)
    }
    
    private var changeWatcher: Timer?

    func stopWatchingChanges() {
        changeWatcher?.invalidate()
        changeWatcher = nil
    }
    
    func startWatchingChanges() {
        print("Starting file change watcher...")
        changeWatcher = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else {
                print("Self is nil, timer stopped.")
                return
            }
            print("Refreshing changes...")
            self.refreshChanges()
        }
    }

    func refreshChanges() {
        print("Running refreshChanges()...")
        let statusOutput = executeGitCommand(arguments: ["status", "--porcelain"])
        
        print("Git Status Output:\n\(statusOutput)") // Debugging output

        let newChanges = statusOutput
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { line -> GitFileChange in
                let statusCode = line.prefix(2).trimmingCharacters(in: .whitespaces)
                let filePath = String(line.dropFirst(3))

                var status: GitFileStatus = .modified

                if statusCode.contains("??") {
                    status = .untracked
                } else if statusCode.contains("A") {
                    status = .added
                } else if statusCode.contains("D") {
                    status = .deleted
                } else if statusCode.contains("AD") {
                    status = .deleted
                } else if statusCode.contains("R") {
                    status = .renamed
                } else if statusCode.contains("M") {
                    status = .modified
                }

                var staged = false
                if statusCode.first != " " && statusCode.first != "?" {
                    staged = true
                }

                return GitFileChange(path: filePath, status: status, staged: staged)
            }

        print("New changes count: \(newChanges.count)")

        DispatchQueue.main.async {
            self.changes = newChanges
            print("UI updated with new changes!")
        }
    }
    
    func refreshStashes() {
        let stashList = executeGitCommand(arguments: ["stash", "list"])
        
        stashes = stashList
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, line -> GitStash in
                // Parse stash description
                let description = line
                    .replacingOccurrences(of: #"stash@{\d+}: "#, with: "", options: .regularExpression)
                
                return GitStash(index: index, description: description)
            }
    }

    func fetchCommits() {
        let arguments = ["log", "--pretty=format:%H|%s|%an|%ad", "--date=short"]
        
        // Call executeGitCommand with the arguments
        let output = executeGitCommand(arguments: arguments)
        
        // Parse the output
        if !output.isEmpty {
            DispatchQueue.main.async {
                self.commits = output.split(separator: "\n").map { line in
                    let parts = line.split(separator: "|", maxSplits: 3, omittingEmptySubsequences: false)
                    return Commit(
                        hash: String(parts[0]),
                        message: String(parts[1]),
                        author: String(parts[2]),
                        date: String(parts[3])
                    )
                }
            }
        } else {
            print("No commits found or error executing git command.")
        }
    }
    
    // Helper function to execute git commands
    private func executeGitCommand(arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        
        // Add the repository path to the arguments
        var fullArguments = ["-C", path]
        fullArguments.append(contentsOf: arguments)
        process.arguments = fullArguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output
            }
        } catch {
            print("Error executing git: \(error.localizedDescription)")
            sendStatusMessage("Error executing git: \(error.localizedDescription)", isError: true)
        }
        
        return ""
    }
    
    // Git operations with status tracking
    private func executeGitOperationAsync(operation: String, arguments: [String], completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.isOperationInProgress = true
                self.currentOperation = operation
                self.sendStatusMessage("Starting operation: \(operation)...")
            }
            
            let result = self.executeGitCommand(arguments: arguments)
            
            DispatchQueue.main.async {
                self.isOperationInProgress = false
                self.currentOperation = ""
                
                if result.contains("error:") || result.contains("fatal:") {
                    self.sendStatusMessage("Operation failed: \(operation)", isError: true)
                } else {
                    self.sendStatusMessage("Operation completed: \(operation)", isSuccess: true)
                }
                
                completion(result)
            }
        }
    }
    
    func pull() {
        executeGitOperationAsync(operation: "Pull", arguments: ["pull"]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func push(remote: String = "origin", branch: String? = nil) {
        var args = ["push", remote]
        if let branch = branch {
            args.append(branch)
        }
        
        executeGitOperationAsync(operation: "Push", arguments: args) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func commit(message: String) {
        executeGitOperationAsync(operation: "Commit", arguments: ["commit", "-m", message]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func stageFile(path: String) {
        executeGitOperationAsync(operation: "Stage file", arguments: ["add", path]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func unstageFile(path: String) {
        executeGitOperationAsync(operation: "Unstage file", arguments: ["reset", "HEAD", path]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func stageAllFiles() {
        executeGitOperationAsync(operation: "Stage all files", arguments: ["add", "."]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func checkout(branch: String) {
        executeGitOperationAsync(operation: "Checkout branch", arguments: ["checkout", branch]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func createBranch(name: String) {
        executeGitOperationAsync(operation: "Create branch", arguments: ["checkout", "-b", name]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func applyStash(index: Int) {
        executeGitOperationAsync(operation: "Apply stash", arguments: ["stash", "apply", "stash@{\(index)}"]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func createStash(message: String? = nil) {
        if let message = message {
            executeGitOperationAsync(operation: "Create stash", arguments: ["stash", "push", "-m", message]) { [weak self] _ in
                self?.refreshStatus()
            }
        } else {
            executeGitOperationAsync(operation: "Create stash", arguments: ["stash", "push"]) { [weak self] _ in
                self?.refreshStatus()
            }
        }
    }
    
    func discardChanges(file: String) {
        executeGitOperationAsync(operation: "Discard changes", arguments: ["checkout", "--", file]) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func getFileDiff(file: String) -> String {
        return executeGitCommand(arguments: ["diff", file])
    }
    
    private func sendStatusMessage(_ message: String, isSuccess: Bool = false, isError: Bool = false) {
        statusCallback?(message, isSuccess, isError)
    }
}
