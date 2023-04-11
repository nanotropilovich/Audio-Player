import Foundation
import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import UIKit
import Combine
class URLStore: ObservableObject {
    @Published var urls: [URL] = []
    func add(url: URL) {
        urls.append(url)
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
                withAnimation {
                    if self.audioPlayer.isPlaying {
                        self.audioPlayer.stopPlaying(at: self.currentTime)
                    } else {
                        if let url = self.fileImporter.selectedFileURL {
                            self.audioPlayer.playAudio(from: url, startTime: self.currentTime)
                        }
                    }
                    self.isPlaying.toggle()
                }
            }) {
                Image(systemName: self.isPlaying ? "stop.circle" : "play.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
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
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    fileImporter.present(from: rootVC)
                }
            }) {
                Text("Import Audio File")
            }
           
            URLListView(store: store)
        }
        .sheet(isPresented: self.$fileImporter.isPresented) {
            DocumentPickerView(fileImporter: self.fileImporter)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            // Print the current list of URLs
            // print(URLStore.urls)
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
    var body: some View {
        List {
            ForEach(store.urls, id: \.self) { url in
                Text("\(url.lastPathComponent)")
            }
        }
    }
}






