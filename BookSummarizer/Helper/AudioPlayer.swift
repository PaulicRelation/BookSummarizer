//
//  AudioPlayer.swift
//  BookSummarizer
//
//  Created by Pavlo Senchenko on 24.10.2023.
//

import UIKit
import AVFoundation

struct Chapter: Equatable {
    static var counter = 0
    let id: Int
    let title:String
    let start:CMTime
    let duration:Int
    
    init(title: String, start: CMTime, duration: Int) {
        Chapter.counter += 1
        self.id = Chapter.counter
        self.title = title
        self.start = start
        self.duration = duration
    }
}

final class MediaManager: GetMetadataProtocol, MediaTimerProtocol {
    
    var currentProgress: Double = 0.0
    var currentChapterId = 0
    var playerTimeObserver: Any?
    
    static var shared: MediaManager = { MediaManager() }()
    private init() { }
}

extension MediaManager: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}

protocol GetMetadataProtocol {
    func loadChapters() async -> [Chapter]?
    func loadArtworkImage() async -> UIImage?
    
}

extension GetMetadataProtocol {
    
    func loadChapters() async -> [Chapter]? {
        guard let audioUrl = Bundle.main.url(forResource: "Sapiens_Sample", withExtension: "m4b") else { return  nil}
        let asset = AVAsset(url: audioUrl)
        var chaptersData: [Chapter] = []
        do {
            let locales =  try await asset.load(.availableChapterLocales)
            for locale in locales {
                let chapters = try await asset.loadChapterMetadataGroups(withTitleLocale: locale ,
                                                                         containingItemsWithCommonKeys: [.commonKeyArtwork])
                
                for chapterMetadata in chapters {
                    let metadataItems = AVMetadataItem.metadataItems(from: chapterMetadata.items, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common)
                    let title = try await metadataItems.first?.load(.stringValue) ?? "Chapter"
                    let startTime = chapterMetadata.timeRange.start
                    let duration = Int(CMTimeGetSeconds(chapterMetadata.timeRange.duration))
                    
                    let chapter = Chapter(title: title,
                                          start: startTime,
                                          duration: duration)
                    chaptersData.append(chapter)
                }
            }
            return chaptersData
        } catch let error as NSError {
            print("Error loading AVAsset: \(error)")
        }
        return nil
    }
    
    func loadArtworkImage() async -> UIImage? {
        if let audioUrl = Bundle.main.url(forResource: "Sapiens_Sample", withExtension: "m4b") {
            do {
                let avAsset =  AVAsset(url: audioUrl)
                let metadata = try await avAsset.load(.metadata)
                
                let artworksMetadataItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork)
                
                if let item = artworksMetadataItems.last,
                   let image = await imageFromItem(item: item) {
                    return image
                } else {
                    print("No artwork found in metadata.")
                }
            } catch let error as NSError {
                print("Error loading AVAsset: \(error)")
            }
        }
        return nil
    }
    
    private func imageFromItem(item: AVMetadataItem) async -> UIImage? {
        do {
            let dataValue = try await item.load(.dataValue)
            return UIImage(data: dataValue!)
        } catch let error as NSError {
            print("Error loading AVAsset: \(error)")
            return nil
        }
    }
}

protocol MediaTimerProtocol {
    func setTimeObserver(for chapter: Chapter, player: AVPlayer)
    func progressToCMTime(value: Double, duration: CMTime) -> CMTime
    func showStringTime(_ seconds: Double) -> String
}

extension MediaTimerProtocol {
    
    func removeCurrentObserver(player: AVPlayer) {
        if let observer = MediaManager.shared.playerTimeObserver {
            player.removeTimeObserver(observer)
        }
    }
    
    func setTimeObserver(for chapter: Chapter, player: AVPlayer) {
        
        let timeInterval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(44100))
        MediaManager.shared.playerTimeObserver = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: nil) { time in
            let totalDuration = Double(chapter.duration)
            let ratio = totalDuration / (time.seconds - chapter.start.seconds)
            let percentage = 100 / ratio
            MediaManager.shared.currentProgress = percentage * 0.01
            NotificationCenter.default.post(Notification(name: Notifications.avPlayerCurrentTimeNotification))
        }
    }

    
    func progressToCMTime(value: Double, duration: CMTime) -> CMTime {
        let ratio = 1 / value
        let total = CMTimeGetSeconds(duration)
        var currentSeconds = total / ratio
        print(currentSeconds)
        if currentSeconds.isNaN {
            currentSeconds = 0.0
        }
        return CMTime(seconds: currentSeconds, preferredTimescale: CMTimeScale(44100))
    }
    
    private func setPlaybackSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        } catch let error {
            print("Error in AVAudio Session\(error.localizedDescription)")
        }
    }
    
    func showStringTime(_ seconds: Double) -> String {
        let minutesString = getMinutesFromSeconds(seconds)
        let secondsString = getSecondsAfterDot(seconds)
        return minutesString + ":" + secondsString
    }
    
    private  func getMinutesFromSeconds(_ number: Double) -> String {
        var num = String()
        let floatMinDuration = String(number / 60)
        if let dotIndex = floatMinDuration.firstIndex(of: ".") {
            let distanceNumber = floatMinDuration.distance(from: floatMinDuration.startIndex, to: dotIndex)
            for (index, char) in floatMinDuration.enumerated() {
                if index < distanceNumber {
                    num.append(char)
                }
            }
        }
        return num
    }
    
    private func getSecondsAfterDot(_ number: Double) -> String {
        if let minutes = Double(getMinutesFromSeconds(number)) {
            
            let secondsInWholeMinutes = minutes * 60
            let incompleteSeconds = number - secondsInWholeMinutes
            let secString = String(incompleteSeconds)
            var num = String()
            if let dotIndex = secString.firstIndex(of: ".") {
                
                let distanceNumber = secString.distance(from: secString.startIndex, to: dotIndex)
                for (index, char) in secString.enumerated() {
                    if index < distanceNumber {
                        num.append(char)
                    }
                }
            }
            if num.count == 1 {
                num.insert("0", at: num.startIndex)
            }
            return String(num)
        } else {
            return ""
        }
    }
    
}
