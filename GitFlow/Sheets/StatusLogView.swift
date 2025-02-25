//
//  StatusLogView.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI
import Luminare

struct StatusLogView: View {
    @EnvironmentObject var gitManager: GitRepositoryManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text("Operation Log")
                    .font(.title2)
                    .padding()
                
                Spacer()
                
                LuminareSection {
                    HStack(spacing: 2) {
                        Button("Clear") {
                            gitManager.clearStatusMessages()
                        }
                        
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(height: 35)
                }
                .buttonStyle(LuminareButtonStyle())
                .frame(width: 200)
            }
            
            LuminareSection {
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
            .listStyle(.sidebar)
        }
        .frame(width: 600, height: 400)
    }
}
