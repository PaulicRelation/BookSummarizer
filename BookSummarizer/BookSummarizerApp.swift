//
//  BookSummarizerApp.swift
//  BookSummarizer
//
//  Created by Pavlo Senchenko on 24.10.2023.
//

import SwiftUI
import ComposableArchitecture

@main
struct BookSummarizerApp: App {
    
    static let store = Store(initialState: BookPlayerFeature.State()) {
        BookPlayerFeature()
            ._printChanges()
    }
    
    var body: some Scene {
        WindowGroup {
            BookPlayerView(store: BookSummarizerApp.store)
        }
    }
}
