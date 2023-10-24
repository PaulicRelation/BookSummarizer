//
//  Color+Palette.swift
//  BookSummarizer
//
//  Created by Pavlo Senchenko on 24.10.2023.
//

import SwiftUI

extension Color {
    
    static var palette: Palette { Palette() }
    
    struct Palette {
        let background = Color(red: 253 / 255, green: 248 / 255, blue: 243 / 255)
    }
    
}
