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

    init() {
        if let data = UserDefaults.standard.data(forKey: "audioFiles"),
           let audioFiles = try? JSONDecoder().decode([AudioFile].self, from: data) {
            urls = audioFiles
        } else {
            urls = []
        }
    }

    func add(url: URL) {
        let audioFile = AudioFile(url: url)
        urls.append(audioFile)
    }

    func removeAll() {
        urls.removeAll()
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
                if let urls = try? PropertyListDecoder().decode([AudioURL].self, from: data) {
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
    @ObservedObject var store: URLStore // обновляем до ObservedObject
    @Binding var currentTime: TimeInterval
    @State private var currentURLIndex: Int = 0
    
    init(store: URLStore, currentTime: Binding<TimeInterval>) { // добавляем инициализатор
        self.store = store
        self._currentTime = currentTime
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.urls, id: \.self) { url in
                    NavigationLink(destination: URLDetailView(urls: store.urls, currentURLIndex: $currentURLIndex)) {
                        Text("\(url.artist ?? "no name") - \(url.name)")

                       
                        
                       
                        
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
    let urls: [AudioFile]
    @Binding var currentURLIndex: Int
    @State private var totalTime: TimeInterval = 0
    @State private var isPlaying = false
    @ObservedObject var audioPlayer = AudioPlayer()
    //@Binding var currentTime: TimeInterval
    func formattedTime(_ time: TimeInterval) -> String {
            let minutes = Int(time / 60)
            let seconds = Int(time.truncatingRemainder(dividingBy: 60))
            return String(format: "%02d:%02d", minutes, seconds)
        }
    var body: some View {
        let url = urls[currentURLIndex]
        let asset = AVURLAsset(url: url.url)
        VStack {
            Text("ya ded")
            Text("\(formattedTime(url.currentTime)) / \(formattedTime(self.totalTime))")
            Slider(value: Binding(get: { url.currentTime }, set: { self.audioPlayer.seek(to: $0) }), in: 0...self.totalTime) {
              
               
            }
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
                        if self.audioPlayer.isPlaying {
                                       self.audioPlayer.stopPlaying(at: url.currentTime)
                            self.isPlaying.toggle()
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
        .frame(width: 300, height: 200) // здесь можно установить нужный размер для VStack

        Text("Album: \(url.album ?? "no album name")")
        Text("Duration: \(url.duration?.description ?? "unknown")")
       let minutes = Int((url.duration ?? 0) / 60)
    let seconds = Int(url.duration?.truncatingRemainder(dividingBy: 60) ?? 0)
       Text(String(format: "%02d:%02d", minutes, seconds))



    }
}





