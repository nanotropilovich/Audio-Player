import Foundation
import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import UIKit
import Combine
class URLStore: ObservableObject {
    @Published var urls: [AudioFile] {
        didSet {
            let data = try? JSONEncoder().encode(urls)
            UserDefaults.standard.set(data, forKey: "audioFiles")
        }
    }
    @Published var folders: [Folder] {
        didSet {
            let data = try? JSONEncoder().encode(folders)
            UserDefaults.standard.set(data, forKey: "folders")
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "audioFiles"),
           let audioFiles = try? JSONDecoder().decode([AudioFile].self, from: data) {
            urls = audioFiles
        } else {
            urls = []
        }
        
        if let data = UserDefaults.standard.data(forKey: "folders"),
           let folders = try? JSONDecoder().decode([Folder].self, from: data) {
            self.folders = folders
        } else {
            self.folders = []
        }
    }
    func getAudioFiles(for folder: Folder?) -> [AudioFile] {
            return urls.filter { $0.folderID == folder?.id }
        }
    func add(url: URL, folderID: UUID? = nil) {
        let audioFile = AudioFile(url: url, folderID: folderID)
        urls.append(audioFile)
    }

    func removeAll() {
        urls.removeAll()
    }

    func remove(atOffsets offsets: IndexSet) {
        urls.remove(atOffsets: offsets)
    }

    func removeFolder(atOffsets offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
    }
}
typealias AudioURL = AudioFile

struct AudioPlayerView: View {
    @StateObject var store = URLStore()
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentTime: TimeInterval
    @ObservedObject var audioPlayer = AudioPlayer()
    @State private var isPlaying = false
    @State private var totalTime: TimeInterval = 0
    @State private var currentFolder: Folder?
    @State private var isAddingFolder = false
    private func deleteFolder(at offsets: IndexSet) {
            store.removeFolder(atOffsets: offsets)
        }
    @StateObject var fileImporter = FileImporter(
            allowedContentTypes: [UTType.audio],
            completion: {_ in
            }
        )
    var body: some View {
           
           VStack {
               Text("Folders")
               
               NavigationView {
                   List {
                       ForEach(store.folders.indices, id: \.self) { index in
                           NavigationLink(destination: URLListView(store: store, currentTime: $currentTime, folder: Binding.constant(store.folders[index]))) {
                               Text(store.folders[index].name)
                           }
                       }
                       .onDelete(perform: deleteFolder)
                   }
                   .listStyle(PlainListStyle())
                   .navigationBarItems(trailing: EditButton())
                   .toolbar {
                       ToolbarItem(placement: .navigationBarTrailing) {
                           Button(action: {
                               isAddingFolder.toggle()
                           }) {
                               Text("Create Folder")
                           }
                           .sheet(isPresented: $isAddingFolder) {
                               AddFolderView(store: store, isPresented: $isAddingFolder)
                           }
                       }
                   }
               }

               if let folder = currentFolder {
                   URLListView(store: store, currentTime: $currentTime, folder: Binding.constant(folder))
               }
           }
       }
   }


struct URLListView: View {
    @ObservedObject var store: URLStore
    @Binding var currentTime: TimeInterval
    @Binding var folder: Folder?
    @StateObject var fileImporter = FileImporter(
                allowedContentTypes: [UTType.audio],
                completion: { _ in
                    
                }
            )
    init(store: URLStore, currentTime: Binding<TimeInterval>,folder: Binding<Folder?>) {
        self.store = store
        self._currentTime = currentTime
        self._folder = folder
    }

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
                List {
                    Section(header: Text("Folders")) {
                        ForEach(store.getAudioFiles(for: folder).indices, id: \.self) { index in
                            let audioFile = store.getAudioFiles(for: folder)[index]
                            NavigationLink(destination:
                                URLDetailView(urls: store.getAudioFiles(for: folder), currentURLIndex: index)
                            ) {
                                Text(audioFile.name)
                            }
                        }
                        .onDelete(perform: deleteFolder)
                    }
                }
            }
            .sheet(isPresented: self.$fileImporter.isPresented) {
                DocumentPickerView(fileImporter: self.fileImporter)
                    .edgesIgnoringSafeArea(.all)
            }
            .onAppear {
                if let data = UserDefaults.standard.value(forKey: "urls") as? Data {
                    if let urls = try? PropertyListDecoder().decode([AudioURL].self, from: data) {
                        store.urls = urls
                    }
                }
            }
            .onChange(of: self.fileImporter.selectedFileURL) { selectedFileURL in
                if let url = selectedFileURL {
                    store.add(url: url, folderID: folder?.id)
                }
            }
            .navigationTitle("Track List")
            .navigationBarItems(trailing: EditButton())
        }
    
    func deleteFolder(at offsets: IndexSet) {
        store.folders.remove(atOffsets: offsets)
    }

    func delete(at offsets: IndexSet) {
        store.urls.remove(atOffsets: offsets)
    }
}

struct URLDetailView: View {
    let urls: [AudioFile]
 
    @State private var currentURLIndex: Int
    @State private var totalTime: TimeInterval = 0
    @State private var isPlaying = false
    @ObservedObject var audioPlayer = AudioPlayer()
    
    init( urls: [AudioFile],currentURLIndex: Int) {
        self._currentURLIndex = State(initialValue: currentURLIndex)
        self.urls = urls
    }
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
        }

      
        var body: some View {
            let url = urls[currentURLIndex]
            let asset = AVURLAsset(url: url.url)
            VStack {
                Text("Now Playing")
                Text("\(formattedTime(url.currentTime)) / \(formattedTime(self.totalTime))")
                Slider(value: Binding(get: { url.currentTime }, set: { self.audioPlayer.seek(to: $0) }), in: 0...self.totalTime)

                .onReceive(self.audioPlayer.$currentTime) { currentTime in
                    url.currentTime = currentTime ?? 0
                }
                .onReceive(self.audioPlayer.$duration) { duration in
                    self.totalTime = duration ?? 0
                }
                .disabled(self.audioPlayer.duration == nil)
                
                Button(action: {
                    withAnimation {
                        if self.audioPlayer.isPlaying {
                            self.audioPlayer.stopPlaying(at: url.currentTime)
                        } else {
                            self.audioPlayer.playAudio(from: url.url, startTime: url.currentTime)
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
                                       if audioPlayer.isPlaying {
                                           audioPlayer.stopPlaying(at: url.currentTime)
                                           isPlaying = false
                                       }
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
                                       if audioPlayer.isPlaying {
                                           audioPlayer.stopPlaying(at: url.currentTime)
                                           isPlaying = false
                                       }
                                       currentURLIndex += 1
                                   }
                               }) {
                                   Image(systemName: "forward.end.fill")
                                       .resizable()
                                       .frame(width: 20, height: 20)
                               }
                               .disabled(currentURLIndex == urls.count - 1)
                           }

                Text("Selected URL: \(url.url.absoluteString)")
            }
            .onDisappear {
                        if audioPlayer.isPlaying {
                            audioPlayer.stopPlaying(at: url.currentTime)
                            isPlaying = false
                        }
                    }
            .frame(width: 300, height: 200)

            Text("Album: \(url.album ?? "no album name")")
            Text("Duration: \(url.duration?.description ?? "unknown")")
            let minutes = Int((url.duration ?? 0) / 60)
            let seconds = Int(url.duration?.truncatingRemainder(dividingBy: 60) ?? 0)
            Text(String(format: "%02d:%02d", minutes, seconds))
        }
        }
