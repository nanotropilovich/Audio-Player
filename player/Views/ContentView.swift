//
//  ContentView.swift
//  player
//
//  Created by Ilya on 09.04.2023.
//

import SwiftUI
struct ContentView: View {
    @State private var currentTime: TimeInterval = 0

    var body: some View {
        AudioPlayerView(currentTime: self.$currentTime)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
