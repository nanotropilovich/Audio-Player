//
//  CreateFolderView.swift
//  player
//
//  Created by Ilya on 13.04.2023.
//

import Foundation
import SwiftUI
struct CreateFolderView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var store: URLStore
    @State private var folderName: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter folder name", text: $folderName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Create Folder") {
                if !folderName.isEmpty {
                    let newFolder = Folder(name: folderName)
                    store.folders.append(newFolder)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .disabled(folderName.isEmpty)
        }
        .padding()
    }
}
