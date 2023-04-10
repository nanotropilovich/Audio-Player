//
//  AudioFileManager.swift
//  player
//
//  Created by Ilya on 09.04.2023.
//

import Foundation
class AudioFileManager: ObservableObject {
    @Published var audioFiles: [AudioFile] = []
    
    func addAudioFile(at url: URL) {
        let audioFile = AudioFile(url: url)
        audioFiles.append(audioFile)
    }
    
    func removeAudioFile(_ audioFile: AudioFile) {
        if let index = audioFiles.firstIndex(where: { $0.id == audioFile.id }) {
            audioFiles.remove(at: index)
        }
    }
}
