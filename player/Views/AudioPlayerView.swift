import Foundation
import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import UIKit
import Combine
class URLStore: ObservableObject {
    @Published var urls: [URL] {
        didSet {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(urls), forKey: "urls")
        }
    }

    init() {
        urls = UserDefaults.standard.value(forKey: "urls") as? [URL] ?? []
    }

    func add(url: URL) {
        urls.append(url)
    }
    func removeAll() {
           urls.removeAll()
       }
}

struct AudioPlayerView: View {
    @StateObject var store = URLStore()
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentTime: TimeInterval
    @ObservedObject var audioPlayer = AudioPlayer()
    @State private var isPlaying = false
    @State private var totalTime: TimeInterval = 0
    @StateObject var fileImporter = FileImporter(
            allowedContentTypes: [UTType.audio],
            completion: {_ in
            }
        )
    var body: some View {
        VStack {
          
          
            Button(action: {
                           store.removeAll()
                       }) {
                           Text("Clear URLs")
                       }
            Button(action: {
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    fileImporter.present(from: rootVC)
                }
            }) {
                Text("Import Audio File")
            }
           
            URLListView(store: store, currentTime: $currentTime)
        }
        .sheet(isPresented: self.$fileImporter.isPresented) {
            DocumentPickerView(fileImporter: self.fileImporter)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
                    if let data = UserDefaults.standard.value(forKey: "urls") as? Data {
                        if let urls = try? PropertyListDecoder().decode([URL].self, from: data) {
                            store.urls = urls
                        }
                    }
                }
                .onChange(of: self.fileImporter.selectedFileURL) { selectedFileURL in
                    if let url = selectedFileURL {
                        store.add(url: url)
                    }
                }
    }
}


struct URLListView: View {
    @ObservedObject var store: URLStore
    @Binding var currentTime: TimeInterval
    @State private var currentURLIndex: Int = 0
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.urls, id: \.self) { url in
                    NavigationLink(destination: URLDetailView(urls: store.urls, currentURLIndex: $currentURLIndex, currentTime: $currentTime)) {
                        Text("\(url.lastPathComponent)")
                    }
                }
                    .onDelete(perform: delete)
                    }
                    .navigationTitle("Track List")
                    .navigationBarItems(trailing: EditButton())
                    }
                    }
    func delete(at offsets: IndexSet) {
        store.urls.remove(atOffsets: offsets)
    }
    }


struct URLDetailView: View {
    let urls: [URL]
    @Binding var currentURLIndex: Int
    @State private var totalTime: TimeInterval = 0
    @State private var isPlaying = false
    @ObservedObject var audioPlayer = AudioPlayer()
    @Binding var currentTime: TimeInterval
    
    var body: some View {
        let url = urls[currentURLIndex]
        
        Slider(value: Binding(get: { self.currentTime }, set: { self.audioPlayer.seek(to: $0) }), in: 0...self.totalTime) {
            Text("")
        }
        .onReceive(self.audioPlayer.$currentTime) { currentTime in
            self.currentTime = currentTime ?? 0
        }
        .onReceive(self.audioPlayer.$duration) { duration in
            self.totalTime = duration ?? 0
        }
        .disabled(self.audioPlayer.duration == nil)
        
        Button(action: {
            withAnimation {
                if self.audioPlayer.isPlaying {
                    self.audioPlayer.stopPlaying(at: self.currentTime)
                } else {
                    self.audioPlayer.playAudio(from: url, startTime: self.currentTime)
                }
                self.isPlaying.toggle()
            }
        }) {
            Image(systemName: self.isPlaying ? "stop.circle" : "play.circle")
                .resizable()
                .frame(width: 50, height: 50)
        }
        
        HStack {
            Button(action: {
                if currentURLIndex > 0 {
                    currentURLIndex -= 1
                }
            }) {
                Image(systemName: "backward.end.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .disabled(currentURLIndex == 0)
            
            Spacer()
            
            Button(action: {
                if currentURLIndex < urls.count - 1 {
                    currentURLIndex += 1
                }
            }) {
                Image(systemName: "forward.end.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .disabled(currentURLIndex == urls.count - 1)
        }
        
        Text("Selected URL: \(url.absoluteString)")
    }
}





