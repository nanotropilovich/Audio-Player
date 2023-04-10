import Foundation
import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import UIKit

struct AudioPlayerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentTime: TimeInterval
    @ObservedObject var audioPlayer = AudioPlayer()
    @State private var isPlaying = false
    @State private var totalTime: TimeInterval = 0

    @StateObject var fileImporter = FileImporter(
        allowedContentTypes: [UTType.audio],
        completion: { url in
            // Do something with the selected URL, such as playing the audio file.
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
        }
        .sheet(isPresented: self.$fileImporter.isPresented) {
            DocumentPickerView(fileImporter: self.fileImporter)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let fileImporter: FileImporter

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: fileImporter.allowedContentTypes)
        picker.delegate = context.coordinator as? UIDocumentPickerDelegate
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        uiViewController.allowsMultipleSelection = false
        uiViewController.shouldShowFileExtensions = true

        if #available(iOS 14.0, *) {
            uiViewController.allowsMultipleSelection = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(fileImporter: fileImporter)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let fileImporter: FileImporter

        init(fileImporter: FileImporter) {
            self.fileImporter = fileImporter
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            fileImporter.selectedFileURL = url
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            fileImporter.selectedFileURL = nil
            fileImporter.isPresented = false
        }
    }
}
