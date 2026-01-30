//
//  ReadingVerseView.swift
//  bible_ios
//
//  Created by Caleb Chiang on 2026-01-30.
//

import SwiftUI

struct ReadingVerseView: View {
    let verse: ChapterVerse
    let geometry: GeometryProxy
    let backgroundIndex: Int
    let isActive: Bool

    @State private var textVisible = false

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Text(verse.text)
                    .font(.custom("Palatino", size: 26))
                    .foregroundColor([3, 9].contains(backgroundIndex) ? .black : .white)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                    .opacity(textVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: textVisible)

                Text(verse.reference)
                    .font(.custom("Palatino", size: 16))
                    .foregroundColor([3, 9].contains(backgroundIndex) ? .black.opacity(0.9) : .white.opacity(0.9))
                    .opacity(textVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.6).delay(0.1), value: textVisible)
            }
            .frame(maxWidth: geometry.size.width * 0.9)
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
        }
        .onChange(of: isActive) { active in
            if active {
                textVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    textVisible = true
                }
            } else {
                textVisible = false
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    textVisible = true
                }
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
}
