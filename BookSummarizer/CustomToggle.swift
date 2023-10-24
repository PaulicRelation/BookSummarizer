//
//  CustomToggle.swift
//  BookSummarizer
//
//  Created by Pavlo Senchenko on 24.10.2023.
//

import SwiftUI

struct CustomToggle: View {
    
    @State private var isMusicSelected = true
    @State private var knobPosition: CGFloat = 0
    
    var body: some View {
        
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: 60)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 60)
                            .fill(Color.white)
                    )
                
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isMusicSelected = true
                            knobPosition = 0
                        }
                    }) {
                        ZStack {
                            Color.blue.clipShape(Circle())
                                .frame(width: 54)
                                .offset(x: knobPosition)
                            Image(systemName: "headphones")
                                .foregroundColor(isMusicSelected ? .white : .black)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isMusicSelected = false
                            knobPosition = 58
                        }
                    }) {
                        ZStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(isMusicSelected ? .black : .white)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }.padding(.leading, -14)
            }
            .frame(width: 118, height: 60)
        }
    }
}

