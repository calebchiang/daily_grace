import SwiftUI
import GRDB

struct HomeView: View {
    @State private var verseStack: [Verse] = []
    @State private var currentIndex: Int = 0
    @State private var totalOffset: CGFloat = 0
    @State private var triggerFade = false

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    ForEach(visibleIndices(), id: \.self) { index in
                        let verse = verseStack[index]

                        VerseView(
                            verse: verse,
                            geometry: geometry,
                            isActive: index == currentIndex
                        )
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
                            let predictedEnd = value.predictedEndTranslation.height

                            if value.translation.height < -threshold {
                                // Animate upward swipe
                                withAnimation(.easeOut(duration: 0.25)) {
                                    totalOffset = -geometry.size.height
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    totalOffset = 0
                                    showNextVerse()
                                }
                            } else if value.translation.height > threshold {
                                // Animate downward swipe
                                withAnimation(.easeOut(duration: 0.25)) {
                                    totalOffset = geometry.size.height
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    totalOffset = 0
                                    showPreviousVerse()
                                }
                            } else {
                                // Not enough — snap back
                                withAnimation(.easeOut(duration: 0.2)) {
                                    totalOffset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    if verseStack.isEmpty {
                        loadInitialVerse()
                    }
                }
            }
        }
        .ignoresSafeArea() // 🔥 critical for full‑screen behavior
    }

    // MARK: - Visible Indices (only render what we need)

    func visibleIndices() -> [Int] {
        guard !verseStack.isEmpty else { return [] }

        var indices = [currentIndex]
        if currentIndex > 0 { indices.append(currentIndex - 1) }
        if currentIndex < verseStack.count - 1 { indices.append(currentIndex + 1) }

        return indices
    }

    // MARK: - Offsets

    func offsetY(for index: Int, height: CGFloat) -> CGFloat {
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

    func showNextVerse() {
        triggerFade = false
        if currentIndex == verseStack.count - 1 {
            loadRandomVerse { verse in
                if let verse = verse {
                    verseStack.append(verse)
                    currentIndex += 1
                    preloadNextIfNeeded()
                    triggerFade = true
                }
            }
        } else {
            currentIndex += 1
            preloadNextIfNeeded()
            triggerFade = true
        }
    }

    func preloadNextIfNeeded() {
        // Preload only if we’re about to reach the end
        if currentIndex >= verseStack.count - 2 {
            loadRandomVerse { next in
                if let next = next {
                    verseStack.append(next)
                }
            }
        }
    }

    func showPreviousVerse() {
        if currentIndex > 0 {
            triggerFade = false
            currentIndex -= 1
            triggerFade = true
        }
    }

    // MARK: - Loading

    func loadInitialVerse() {
        loadRandomVerse { firstVerse in
            if let firstVerse = firstVerse {
                verseStack.append(firstVerse)
                
                triggerFade = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                triggerFade = true
                            }

                // Preload second verse immediately
                loadRandomVerse { secondVerse in
                    if let secondVerse = secondVerse {
                        verseStack.append(secondVerse)
                    }
                }
            }
        }
    }

    func loadRandomVerse(completion: @escaping (Verse?) -> Void) {
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
        WHERE tags.name = 'encouragement'
        ORDER BY RANDOM()
        LIMIT 1
        """

        do {
            let dbQueue = DatabaseManager.shared.dbQueue

            try dbQueue.read { db in
                let row = try Row.fetchOne(db, sql: sql)

                DispatchQueue.main.async {
                    if let row = row {
                        let text: String = row["text"]
                        let book: String = row["book"]
                        let chapter: Int = row["chapter"]
                        let verse: Int = row["verse"]

                        let reference = "\(book) \(chapter):\(verse)"
                        let nextBgIndex = verseStack.isEmpty
                            ? Int.random(in: 1...10)
                            : ((verseStack.last?.backgroundIndex ?? 0) % 10) + 1

                        completion(
                            Verse(
                                text: text,
                                reference: reference,
                                backgroundIndex: nextBgIndex
                            )
                        )
                    } else {
                        completion(nil)
                    }
                }
            }
        } catch {
            print("DB error:", error)
            completion(nil)
        }
    }
}

struct VerseView: View {
    let verse: Verse
    let geometry: GeometryProxy
    let isActive: Bool

    @State private var textVisible = false

    var body: some View {
        ZStack {
            Image("bg\(verse.backgroundIndex)")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(verse.text)
                    .font(.custom("Palatino", size: 26))
                    .foregroundColor([3, 9].contains(verse.backgroundIndex) ? .black : .white)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                    .opacity(textVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: textVisible)

                Text(verse.reference)
                    .font(.custom("Palatino", size: 16))
                    .foregroundColor([3, 9].contains(verse.backgroundIndex) ? .black.opacity(0.9) : .white.opacity(0.9))
                    .opacity(textVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.6).delay(0.1), value: textVisible)
            }
            .frame(maxWidth: geometry.size.width * 0.9)
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
        }
        .onChange(of: isActive) { active in
            if active {
                // Fade in AFTER slide is fully settled
                textVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    textVisible = true
                }
            } else {
                // Instantly hide when slide is no longer active
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
