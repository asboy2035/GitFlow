//
//  StatusMessageRow.swift
//  GitFlow
//
//  Created by ash on 2/25/25.
//

import SwiftUI

struct StatusMessageRow: View {
    let message: StatusMessage
    
    var body: some View {
        HStack {
            if message.isSuccess {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            } else if message.isError {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading) {
                Text(message.message)
                
                Text(formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: message.timestamp)
    }
}
