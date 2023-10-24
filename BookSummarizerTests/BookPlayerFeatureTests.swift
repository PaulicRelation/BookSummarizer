//
//  BookPlayerFeatureTests.swift
//  BookSummarizerTests
//
//  Created by Pavlo Senchenko on 24.10.2023.
//

import Foundation
import CoreMedia
import SwiftUI
import XCTest
import ComposableArchitecture

@testable import BookSummarizer

@MainActor

final class BookPlayerFeatureTests: XCTestCase {

    func testPlayPause() async {
        let store = TestStore(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        }
        await store.send(.playPauseButtonTapped) {
            $0.isPlaying = true
        }
        await store.send(.playPauseButtonTapped) {
            $0.isPlaying = false
        }
    }
    
    func testAssignChapters() async {
        
        let store = TestStore(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        }
        
        let chapters: [Chapter] = [Chapter(title: "First", start: CMTime(), duration: 10),
                                   Chapter(title: "Second", start: CMTime(), duration: 10)]
        
        await store.send(.assignChapters(chapters)) {
            $0.chapters = chapters
        }
        
    }
    
    func testNextAndPreviousChapter() async {
        let store = TestStore(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        }
        
        let chapters: [Chapter] = [Chapter(title: "First", start: CMTime(), duration: 10),
                                   Chapter(title: "Second", start: CMTime(), duration: 10)]
        
        await store.send(.assignChapters(chapters)) {
            $0.chapters = chapters
        }
        
        await store.send(.nextChapterButtonTapped) {
            $0.currentChapterNumber = 1
        }
        await store.send(.previousChapterButtonTapped) {
            $0.currentChapterNumber = 0
        }
        
    }
   
    func testPlaybackSpeedChanged() async {
        let store = TestStore(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        }
        
        await store.send(.playbackSpeedChanged) {
            $0.playbackSpeedIndex = 1.25
        }
        
        await store.send(.playbackSpeedChanged) {
            $0.playbackSpeedIndex = 1.5
        }
        await store.send(.playbackSpeedChanged) {
            $0.playbackSpeedIndex = 1.75
        }
        await store.send(.playbackSpeedChanged) {
            $0.playbackSpeedIndex = 2.0
        }
        await store.send(.playbackSpeedChanged) {
            $0.playbackSpeedIndex = 0.5
        }
        await store.send(.playbackSpeedChanged) {
            $0.playbackSpeedIndex = 0.75
        }
        await store.send(.playbackSpeedChanged) {
            $0.playbackSpeedIndex = 1.0
        }
    }
    
    func testProgressChange() async {
        
        let store = TestStore(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        }
        
        await store.send(.progressChanged(0.5)) {
            $0.progress = 0.5
        }
        
    }
    
}
