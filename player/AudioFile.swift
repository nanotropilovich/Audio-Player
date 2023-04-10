//
//  AudioFile.swift
//  player
//
//  Created by Ilya on 09.04.2023.
//

import Foundation
import AVFoundation
import CoreMedia


struct AudioFile: Identifiable, Equatable, Codable {
    let id = UUID()
    let url: URL
    let name: String
    var artist: String?
    var album: String?
    let duration: TimeInterval?
    var isPlaying = false
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.artist = nil
        self.album = nil
        self.duration = nil
    }
    
    init(url: URL, metadata: [AVMetadataItem]) async {
        self.url = url
        self.name = url.lastPathComponent

        let artistItem = metadata.first(where: { $0.commonKey == AVMetadataKey.commonKeyArtist })
        if let artistItem = artistItem {
            try? await artistItem.loadValuesAsynchronously(forKeys: [AVMetadataKey.commonKeyTitle.rawValue])
            self.artist = artistItem.stringValue
        }

        let albumItem = metadata.first(where: { $0.commonKey == AVMetadataKey.commonKeyAlbumName })
        if let albumItem = albumItem {
            try? await albumItem.loadValuesAsynchronously(forKeys: [AVMetadataKey.commonKeyTitle.rawValue])
            self.album = albumItem.stringValue
        }

        self.duration = AVAsset(url: url).duration.seconds
    }
    
    func formattedDuration() -> String {
        guard let duration = self.duration else {
            return ""
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? ""
    }
}




class AudioFileManager {
    private static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private static let audioFilesURL = documentsDirectory.appendingPathComponent("audioFiles").appendingPathExtension("json")
    
    static func loadAudioFiles() -> [AudioFile] {
        guard let data = try? Data(contentsOf: audioFilesURL),
              let audioFiles = try? JSONDecoder().decode([AudioFile].self, from: data) else {
            return []
        }
        return audioFiles
    }
    
    static func saveAudioFiles(_ audioFiles: [AudioFile]) {
        let data = try? JSONEncoder().encode(audioFiles)
        try? data?.write(to: audioFilesURL)
    }
    
    static func deleteAudioFile(_ audioFile: AudioFile) {
        var audioFiles = loadAudioFiles()
        guard let index = audioFiles.firstIndex(of: audioFile) else {
            return
        }
        audioFiles.remove(at: index)
        saveAudioFiles(audioFiles)
    }
    
    static func addAudioFile(_ audioFile: AudioFile) {
        var audioFiles = loadAudioFiles()
        audioFiles.append(audioFile)
        saveAudioFiles(audioFiles)
    }
}
