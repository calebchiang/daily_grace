//
//  ReadingView.swift
//  bible_ios
//
//  Created by Caleb Chiang on 2026-01-30.
//

import SwiftUI
import GRDB

struct ChapterVerse: Identifiable {
    let id = UUID()
    let text: String
    let reference: String
}

struct ReadingView: View {

    let book: String
    let chapter: Int

    @State private var verses: [ChapterVerse] = []
    @State private var currentIndex: Int = 0
    @State private var totalOffset: CGFloat = 0
    @State private var textVisible = false

    private let backgroundIndex = Int.random(in: 1...10)

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {

                    // Background (fixed)
                    Image("bg\(backgroundIndex)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()

                    // Verse pages
                    ForEach(visibleIndices(), id: \.self) { index in
                        let verse = verses[index]

                        ReadingVerseView(
                            verse: verse,
                            geometry: geometry,
                            backgroundIndex: backgroundIndex,
                            isActive: index == currentIndex
                        )
                        .frame(maxWidth: geometry.size.width * 0.9)
                        .offset(y: offsetY(for: index, height: geometry.size.height))
                        .zIndex(index == currentIndex ? 1 : 0)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            totalOffset = value.translation.height
                        }
                        .onEnded { value in
                            let threshold = geometry.size.height * 0.1

                            if value.translation.height < -threshold {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    totalOffset = -geometry.size.height
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    totalOffset = 0
                                    showNext()
                                }
                            } else if value.translation.height > threshold {
                                guard currentIndex > 0 else {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        totalOffset = 0
                                    }
                                    return
                                }

                                withAnimation(.easeOut(duration: 0.25)) {
                                    totalOffset = geometry.size.height
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    totalOffset = 0
                                    showPrevious()
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    totalOffset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    if verses.isEmpty {
                        loadChapter()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Visible indices (same as HomeView)

    private func visibleIndices() -> [Int] {
        guard !verses.isEmpty else { return [] }

        var indices = [currentIndex]
        if currentIndex > 0 { indices.append(currentIndex - 1) }
        if currentIndex < verses.count - 1 { indices.append(currentIndex + 1) }
        return indices
    }

    private func offsetY(for index: Int, height: CGFloat) -> CGFloat {
        if index == currentIndex {
            return totalOffset
        } else if index == currentIndex - 1 {
            return -height + totalOffset
        } else if index == currentIndex + 1 {
            return height + totalOffset
        }
        return 0
    }

    // MARK: - Navigation

    private func showNext() {
        guard currentIndex < verses.count - 1 else { return }
        textVisible = false
        currentIndex += 1
        fadeIn()
    }

    private func showPrevious() {
        guard currentIndex > 0 else { return }
        textVisible = false
        currentIndex -= 1
        fadeIn()
    }

    private func fadeIn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            textVisible = true
        }
    }

    // MARK: - Load chapter

    private func loadChapter() {
        let sql = """
        SELECT verses_web.text, verses_web.verse_number
        FROM verses_web
        JOIN chapters ON verses_web.chapter_id = chapters.id
        JOIN books ON chapters.book_id = books.id
        WHERE books.name = ?
          AND chapters.number = ?
        ORDER BY verses_web.verse_number ASC
        """

        let dbQueue = DatabaseManager.shared.dbQueue

        do {
            try dbQueue.read { db in
                let rows = try Row.fetchAll(db, sql: sql, arguments: [book, chapter])

                DispatchQueue.main.async {
                    verses = rows.map {
                        let verseNum: Int = $0["verse_number"]
                        let text: String = $0["text"]
                        return ChapterVerse(
                            text: text,
                            reference: "\(book) \(chapter):\(verseNum)"
                        )
                    }

                    verses.append(
                        ChapterVerse(
                            text: "End of Chapter",
                            reference: ""
                        )
                    )

                    fadeIn()
                }
            }
        } catch {
            print("DB error:", error)
        }
    }
}
