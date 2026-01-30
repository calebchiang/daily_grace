//
//  verse.swift
//  bible_ios
//
//  Created by Caleb Chiang on 2026-01-29.
//

import Foundation

struct Verse: Identifiable {
    let id = UUID()
    let text: String
    let reference: String
    let backgroundIndex: Int
}
