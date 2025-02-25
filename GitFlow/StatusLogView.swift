//
//  StatusLogView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI

struct StatusLogView: View {
    @EnvironmentObject var gitManager: GitRepositoryManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text("Git Operation Status Log")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    gitManager.clearStatusMessages()
                }
                .buttonStyle(.bordered)
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            List {
                ForEach(gitManager.statusMessages.reversed()) { message in
                    StatusMessageRow(message: message)
                }
                
                if gitManager.statusMessages.isEmpty {
                    Text("No status messages")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .frame(width: 600, height: 400)
    }
}
