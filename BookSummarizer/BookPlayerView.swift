//
//  BookPlayerView.swift
//  BookSummarizer
//
//  Created by Pavlo Senchenko on 24.10.2023.
//

import SwiftUI
import ComposableArchitecture
import AVFoundation

struct BookPlayerView: View {
    
    let store: StoreOf<BookPlayerFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            
            ZStack {
                Color.palette.background.ignoresSafeArea()
                VStack {
                    
                    // Cover
                    viewStore.bookCoverImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 230, height: 350)
                        .padding(30)
                    
                    // Chapter
                    Text("Key point \(viewStore.currentChapter?.id ?? 0) of \(viewStore.chapters.count)")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    // ChapterTitle
                    Text(viewStore.currentChapterTitle)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .padding(.horizontal, 50)
                        .padding(.vertical, 0)
                        .lineLimit(nil)
                        .frame(height: 45)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                    
                    //Slider
                    Slider(value: viewStore.binding(get: { $0.progress }, send: { .progressChanged($0) }), in: 0.0...1.0)
                    
                        .onAppear {
                            UISlider.appearance().setThumbImage( UIImage(systemName: "circle.fill"), for: .normal)
                        }
                        .padding(.horizontal, 40)
                        .overlay(
                            HStack {
                                Text(viewStore.currentTimeString)
                                Spacer()
                                Text(viewStore.chapterDurationString)
                            }
                                .font(.system(size: 13, weight: .regular, design: .default))
                                .foregroundColor(.gray)
                        )
                        .padding(.horizontal,28)
                    
                    // SpeedChanger
                    HStack {
                        Button(action: {
                            viewStore.send(.playbackSpeedChanged)
                        }, label: {
                            Text("Speed x\(viewStore.playbackSpeedIndex.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", viewStore.playbackSpeedIndex) : String(format: "%.2f", viewStore.playbackSpeedIndex))")
                                .font(.system(size: 13, weight: .medium, design: .default)
                                )
                        })
                        .frame(width: 78, height: 10)
                        .padding(12)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.black)
                        .cornerRadius(6)
                    }
                    
                    // Audio Control
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: {
                            viewStore.send(.previousChapterButtonTapped)
                        }) {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundColor(viewStore.currentChapterNumber == 0 ? .gray : .black)
                        }
                        .disabled(viewStore.currentChapterNumber == 0)
                        
                        Spacer()
                        Button(action: {
                            viewStore.send(.rewindButtonTapped)
                        }) {
                            Image(systemName: "gobackward.5")
                        }
                        
                        
                        Spacer()
                        Button(action: {
                            viewStore.send(.playPauseButtonTapped)
                        }) {
                            Image(systemName: viewStore.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 46))
                                .frame(width: 50,height: 50)
                        }
                        Spacer()
                        Button(action: {
                            viewStore.send(.fastForwardButtonTapped)
                        }) {
                            Image(systemName: "goforward.10")
                        }
                        Spacer()
                        Button(action: {
                            viewStore.send(.nextChapterButtonTapped)
                        }) {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundColor(viewStore.currentChapterNumber == (viewStore.chapters.count - 1) ? .gray : .black)
                        }
                        .disabled(viewStore.currentChapterNumber == (viewStore.chapters.count - 1))
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 60)
                    .font(.system(size: 30))
                    CustomToggle()
                    
                }
                .padding(0)
                .foregroundColor(.black)
                .onReceive(viewStore.avPlayerCurrentTimeNotification) { _ in
                    guard viewStore.currentChapterNumber == MediaManager.shared.currentChapterId else { return }
                    viewStore.send(.assignProgress(MediaManager.shared.currentProgress))
                }
            }
        }

        .onAppear() {
            store.send(.getMetadata)
            store.send(.initAvPlayer)
        }
    }
    
}

#Preview {
    BookPlayerView(
        store: Store(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        }
    )}

