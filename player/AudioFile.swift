//
//  AudioFile.swift
//  player
//
//  Created by Ilya on 09.04.2023.
//


import Foundation
import AVFoundation
import CoreMedia
import Combine

class AudioFile: ObservableObject, Identifiable, Equatable, Codable, Hashable {
    static func == (lhs: AudioFile, rhs: AudioFile) -> Bool {
        lhs.id == rhs.id
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        name = try container.decode(String.self, forKey: .name)
        artist = try container.decodeIfPresent(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(name, forKey: .name)
        try container.encode(artist, forKey: .artist)
        try container.encode(album, forKey: .album)
        try container.encode(duration, forKey: .duration)
    }
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case name
        case artist
        case album
        case duration
        case isPlaying
        case currentTime
    }

    let id = UUID()
    let url: URL
    let name: String
    @Published var artist: String?
    @Published var album: String?
    let duration: TimeInterval?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0

    private var cancellables = Set<AnyCancellable>()

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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func togglePlaying() {
        isPlaying.toggle()
    }

    func setCurrentTime(_ time: TimeInterval) {
        currentTime = time
    }

  

    func bind(to player: AVPlayer) {
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
        }
    }
    
    func play() {
        isPlaying = true
    }
    
    func pause() {
        isPlaying = false
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
    static func numberOfFiles() -> Int {
            let audioFiles = loadAudioFiles()
            return audioFiles.count
        }
    static func saveAudioFiles(_ audioFiles: [AudioFile]) {
        let data = try? JSONEncoder().encode(audioFiles)
        try? data?.write(to: audioFilesURL)
    }
    static func deleteAllAudioFiles() {
        var audioFiles = loadAudioFiles()
        audioFiles.removeAll()
        saveAudioFiles(audioFiles)
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
