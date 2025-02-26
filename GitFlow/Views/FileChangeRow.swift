//
//  FileChangeRow.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI
import Luminare

struct FileChangeRow: View {
    let change: GitFileChange
    let action: () -> Void
    let viewDiff: () -> Void
    let discard: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: change.status.icon)
                .foregroundColor(change.status.color)
            
            VStack(alignment: .leading) {
                Text(change.filename)
                    .fontWeight(.medium)
                
                Text(change.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: viewDiff) {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundStyle(.foreground)
            }
            .help("Diff")
            .buttonStyle(.borderless)
            
            Button(action: action) {
                Label(
                    change.staged ? "Unstage" : "Stage",
                    systemImage: change.staged ? "xmark" : "checkmark"
                )
            }
            .frame(width: 100)
            .buttonStyle(LuminareCompactButtonStyle())
            
            Button(action: discard) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .help("Discard")
            .buttonStyle(.borderless)
        }
    }
}
