//
//  Structures.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import Foundation
import SwiftUICore

struct Commit: Identifiable {
    let id = UUID()
    let hash: String
    let message: String
    let author: String
    let date: String
}

struct StatusMessage: Identifiable {
    let id = UUID()
    let message: String
    let timestamp = Date()
    let isSuccess: Bool
    let isError: Bool
}

struct GitBranch: Identifiable {
    let id = UUID()
    let name: String
    let isRemote: Bool
    let isCurrent: Bool
}

struct GitRemote: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let type: String
}

enum GitFileStatus {
    case modified
    case added
    case deleted
    case renamed
    case untracked
    
    var color: Color {
        switch self {
        case .modified: return .blue
        case .added: return .green
        case .deleted: return .red
        case .renamed: return .purple
        case .untracked: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .modified: return "pencil"
        case .added: return "plus"
        case .deleted: return "minus"
        case .renamed: return "arrow.triangle.swap"
        case .untracked: return "questionmark"
        }
    }
}

struct GitFileChange: Identifiable {
    let id = UUID()
    let path: String
    let status: GitFileStatus
    let staged: Bool
    
    var filename: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}

struct GitStash: Identifiable {
    let id = UUID()
    let index: Int
    let description: String
}


struct AlertInfo: Identifiable {
    var id: UUID
    var message: String
}
