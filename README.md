# 🎵🎧 Audio Player 🎧🎵

🔥 A simple and customizable audio player in Swift with a powerful set of features! 🔥

## 🌟 Features:
- 🎶 Play, pause, and seek functionality
- 📁 Import audio files using the `FileImporter` class
- 🎨 Display and update metadata (artist, album, etc.)
- 🔄 Bind audio playback to an `AVPlayer`
- 📚 Move audio files to different folders
- 🎛️ Customizable and extendable

## 🎬 Usage:
```swift
// Import audio file
let fileImporter = FileImporter(allowedContentTypes: [.audio])
fileImporter.present(from: yourViewController)

// Create an AudioFile instance
let audioFile = AudioFile(url: fileURL)

// Initialize the AudioPlayer and start playing
let audioPlayer = AudioPlayer()
audioPlayer.playAudio(from: audioFile.url)

// Control playback
audioPlayer.play()
audioPlayer.pause()
audioPlayer.seek(to: desiredTime)

// Update metadata
await audioFile.updateMetadata()

// Move audio file to a specific folder
audioFile.moveToFolder(folder)
```
## 🧩 Code Overview:
📁 FileImporter: A class that handles importing audio files using a document picker.
🎵 AudioFile: A model representing an audio file with metadata and playback information.
🔊 AudioPlayer: A class that handles audio playback using an AVAudioPlayer instance.
🎚️ Folder: A simple model representing a folder for organizing your audio files.
Feel free to customize the classes and extend their functionality as needed. The provided code is a solid foundation for building an amazing audio player tailored to your app's requirements! 🎉🔧

Enjoy your new awesome audio player! 🎉🎶🎧

Don't forget to give this project a ⭐ if you found it useful! 😃
