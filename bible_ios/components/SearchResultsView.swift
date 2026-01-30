//
//  SearchResultsView.swift
//  bible_ios
//
//  Created by Caleb Chiang on 2026-01-29.
//

import SwiftUI
import GRDB

struct SearchResultsView: View {
    let query: String

    @State private var verses: [Verse] = []
    @State private var isTag = false
    @State private var page = 0
    
    private let pageSize = 8
    private let tags = [
        "anxiety", "encouragement", "forgiveness",
        "healing", "hope", "peace", "stress"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(verses.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verses[index].text)
                            .font(.custom("Palatino", size: 18))
                            .foregroundColor(.primary)

                        Text(verses[index].reference)
                            .font(.custom("Palatino", size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    if index < verses.count - 1 {
                        Divider()
                            .background(Color(.systemGray4))
                            .padding(.horizontal)
                    }
                }

                if isTag {
                    Button("Load more") {
                        page += 1
                        fetchTagVerses()
                    }
                    .font(.custom("Palatino", size: 16))
                    .foregroundColor(.blue)
                    .padding()
                }
            }
            .padding(.top, 8)
        }
        .onAppear { load() }
        .onChange(of: query) { _ in load() }
    }

    // MARK: - Logic

    private func load() {
        verses = []
        page = 0
        isTag = tags.contains(query.lowercased())

        if isTag {
            fetchTagVerses()
        } else {
            fetchSingleVerse()
        }
    }

    // MARK: - DB Queries

    private func fetchTagVerses() {
        let sql = """
        SELECT
            verses_web.text AS text,
            books.name AS book,
            chapters.number AS chapter,
            verses_web.verse_number AS verse
        FROM verses_web
        JOIN chapters ON verses_web.chapter_id = chapters.id
        JOIN books ON chapters.book_id = books.id
        JOIN verse_tags ON verses_web.id = verse_tags.verse_id
        JOIN tags ON verse_tags.tag_id = tags.id
        WHERE tags.name = ?
        ORDER BY RANDOM()
        LIMIT ? OFFSET ?
        """

        do {
            let dbQueue = DatabaseManager.shared.dbQueue
            try dbQueue.read { db in
                let rows = try Row.fetchAll(
                    db,
                    sql: sql,
                    arguments: [query.lowercased(), pageSize, page * pageSize]
                )

                DispatchQueue.main.async {
                    verses.append(contentsOf: rows.compactMap { row in
                        guard
                            let text: String = row["text"],
                            let book: String = row["book"],
                            let chapter: Int = row["chapter"],
                            let verseNum: Int = row["verse"]
                        else {
                            return nil
                        }

                        return Verse(
                            text: text,
                            reference: "\(book) \(chapter):\(verseNum)",
                            backgroundIndex: Int.random(in: 1...10)
                        )
                    })
                }
            }
        } catch {
            print("DB error:", error)
        }
    }

    private func fetchSingleVerse() {
        let parts = query.split(separator: " ")
        guard parts.count >= 2 else { return }

        let book = parts.dropLast().joined(separator: " ")
        let cv = parts.last!.split(separator: ":")

        guard cv.count == 2,
              let chapter = Int(cv[0]),
              let verse = Int(cv[1]) else { return }

        let sql = """
        SELECT
            verses_web.text AS text,
            books.name AS book,
            chapters.number AS chapter,
            verses_web.verse_number AS verse
        FROM verses_web
        JOIN chapters ON verses_web.chapter_id = chapters.id
        JOIN books ON chapters.book_id = books.id
        WHERE books.name = ?
          AND chapters.number = ?
          AND verses_web.verse_number = ?
        LIMIT 1
        """

        do {
            let dbQueue = DatabaseManager.shared.dbQueue
            try dbQueue.read { db in
                if let row = try Row.fetchOne(db, sql: sql, arguments: [book, chapter, verse]) {
                    DispatchQueue.main.async {
                        if
                            let text: String = row["text"],
                            let book: String = row["book"],
                            let chapter: Int = row["chapter"],
                            let verseNum: Int = row["verse"]
                        {
                            verses = [
                                Verse(
                                    text: text,
                                    reference: "\(book) \(chapter):\(verseNum)",
                                    backgroundIndex: Int.random(in: 1...10)
                                )
                            ]
                        }
                    }
                }
            }
        } catch {
            print("DB error:", error)
        }
    }
}

