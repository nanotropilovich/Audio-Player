//
//  AddFolderView.swift
//  player
//
//  Created by Ilya on 13.04.2023.
//

import Foundation
import SwiftUI
struct AddFolderView: View {
    @ObservedObject var store: URLStore
    @Binding var isPresented: Bool
    @State private var folderName: String = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Folder Name", text: $folderName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    let folder = Folder(name: folderName)
                    store.folders.append(folder)
                    isPresented = false
                }) {
                    Text("Create Folder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationBarTitle("New Folder", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}
