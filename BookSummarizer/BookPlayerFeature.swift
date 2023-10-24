//
//  BookPlayerFeature.swift
//  BookSummarizer
//
//  Created by Pavlo Senchenko on 24.10.2023.
//

import ComposableArchitecture
import AVFoundation
import SwiftUI

struct Notifications {
    static let avPlayerCurrentTimeNotification: NSNotification.Name = NSNotification.Name("avPlayerCurrentTimeNotification")
}

struct BookPlayerFeature: Reducer {
  
    struct State: Equatable {

        let avPlayerCurrentTimeNotification = NotificationCenter.default.publisher(for: Notifications.avPlayerCurrentTimeNotification)
        var playbackSpeedIndex: Float = 1.0
        var isPlaying = false
        var progress: Double = 0.0
        var currentTimeString: String {
            if let currentChapter = currentChapter {
                let cmTime = MediaManager.shared.progressToCMTime(value: progress,
                                                                 duration: CMTime(seconds: Double(currentChapter.duration),
                                                                                  preferredTimescale: CMTimeScale(44100)))
                let chapterDurationString = MediaManager.shared.showStringTime(cmTime.seconds)
                return chapterDurationString
            } else {
                return "0:00"
            }
        }
        var chapterDurationString: String {
            if let currentChapter = currentChapter {
              let chapterDurationString = MediaManager.shared.showStringTime(Double(currentChapter.duration))
                return chapterDurationString
            } else {
                return "0:00"
            }
        }
        var currentChapterNumber = 0
        var currentChapterTitle: String {
            guard (chapters.count - 1) >= currentChapterNumber  else { return "" }
            return currentChapter?.title ?? "Design is not how a thing looks, but how it works"
        }
        
        var bookCoverImage = Image("book_cover")
        
        var isToggled = false
        var player: AVPlayer?
        var chapters: [Chapter] = []
        var currentChapter: Chapter? {
            guard (chapters.count - 1) >= currentChapterNumber else { return nil }
            return chapters[currentChapterNumber]
        }
    }
    
    enum Action: Equatable {
        case playbackSpeedChanged
        case playPauseButtonTapped
        case progressChanged(Double)
        case previousChapterButtonTapped
        case rewindButtonTapped
        case fastForwardButtonTapped
        case nextChapterButtonTapped
        case getMetadata
        case assignArtwork(UIImage?)
        case assignChapters([Chapter]?)
        case initAvPlayer
        case assignProgress(Double)
    }

    func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action>  {
                
        switch action {
            
        case .playbackSpeedChanged:
            let newSpeed = state.playbackSpeedIndex + 0.25
            state.playbackSpeedIndex = newSpeed > 2 ? 0.5 : newSpeed
            let wasPlaying = state.isPlaying
            state.player?.rate = state.playbackSpeedIndex
            
            if !wasPlaying {
                state.player?.pause()
            }
            return .none
            
        case .playPauseButtonTapped:
            state.isPlaying.toggle()
            switch state.isPlaying {
            case true: state.player?.rate = state.playbackSpeedIndex
            case false: state.player?.pause()
            }
            return .none
            
        case .progressChanged(let newProgress):
            state.progress = newProgress
            print(state.progress)
            if let currentChapter = state.currentChapter {
                let cmTime = MediaManager.shared.progressToCMTime(value: newProgress,
                                                                 duration: CMTime(seconds: Double(currentChapter.duration),
                                                                                  preferredTimescale: CMTimeScale(44100)))
                state.player?.seek(to: cmTime + currentChapter.start)
            }
            return .none
            
        case .previousChapterButtonTapped:
            guard state.currentChapterNumber > 0 else { return .none }
            if let player = state.player {
                MediaManager.shared.removeCurrentObserver(player: player)
            }
            state.progress = 0
            MediaManager.shared.currentChapterId = state.currentChapterNumber
            state.currentChapterNumber -= 1

            if let currentChapter = state.currentChapter,
             let player = state.player {
                MediaManager.shared.setTimeObserver(for: currentChapter,
                                                   player: player)
            }
            if let seekDate = state.currentChapter?.start {
                state.player?.seek(to: seekDate)
            }
            return .none
            
        case .rewindButtonTapped:
            
            guard let player = state.player else { return .none }
            let currentTime = player.currentTime()
            let rewindTime = CMTimeMakeWithSeconds(-5, preferredTimescale: CMTimeScale(44100))
            let newTime = CMTimeAdd(currentTime, rewindTime)
            player.seek(to: newTime)
            return .none
            
        case .fastForwardButtonTapped:
            guard let player = state.player else { return .none }
            let currentTime = player.currentTime()
            let rewindTime = CMTimeMakeWithSeconds(10, preferredTimescale: CMTimeScale(44100))
            let newTime = CMTimeAdd(currentTime, rewindTime)
            player.seek(to: newTime)
            return .none
            
            
        case .nextChapterButtonTapped:
            guard state.currentChapterNumber < (state.chapters.count - 1) else { return .none }
            if let player = state.player {
                MediaManager.shared.removeCurrentObserver(player: player)
            }
          
            state.currentChapterNumber += 1
            MediaManager.shared.currentChapterId = state.currentChapterNumber
            state.progress = 0

            if let currentChapter = state.currentChapter,
             let player = state.player {
                MediaManager.shared.setTimeObserver(for: currentChapter,
                                                   player: player)
            }
            if let seekDate = state.currentChapter?.start {
                state.player?.seek(to: seekDate)
            }
            return .none
            
        case .getMetadata:
            return .run { send in
                let uiImage = await MediaManager.shared.loadArtworkImage()
             await send(.assignArtwork(uiImage))
                let chapters = await MediaManager.shared.loadChapters()
               await send(.assignChapters(chapters))
            }
        case .assignArtwork( let image):
            if let image = image {
              state.bookCoverImage = Image(uiImage: image)
            }
            return .none
            
        case .assignChapters(let chapters):
            if let chapters = chapters {
                state.chapters = chapters
            }
                if let currentChapter = state.currentChapter,
                 let player = state.player {
                    MediaManager.shared.setTimeObserver(for: currentChapter,
                                                       player: player)
                }
            return .none
        case .initAvPlayer:
            
            if let audioUrl = Bundle.main.url(forResource: "Sapiens_Sample", withExtension: "m4b")
               {
                state.player = AVPlayer(url: audioUrl)
                state.player?.pause()
               }
            
            return .none
        case .assignProgress(let newProgress):
     
            state.progress = newProgress
            return .run { send in
                guard newProgress >= 1.0 else { return }
                 await send(.nextChapterButtonTapped)
            }
        }
    }
}


