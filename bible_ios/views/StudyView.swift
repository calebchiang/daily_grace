import SwiftUI
import GRDB

struct StudyView: View {

    enum Testament: String, CaseIterable {
        case old = "Old Testament"
        case new = "New Testament"
    }

    struct SelectedChapter: Identifiable, Hashable {
        let id = UUID()
        let book: String
        let chapter: Int
    }

    @State private var selectedTestament: Testament = .old
    @State private var expandedBooks: Set<String> = []
    @State private var chaptersPerBook: [String: Int] = [:]
    @State private var selectedChapter: SelectedChapter?

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private let oldTestamentBooks = [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
        "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
        "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
        "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
        "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
        "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
        "Zephaniah", "Haggai", "Zechariah", "Malachi"
    ]

    private let newTestamentBooks = [
        "Matthew", "Mark", "Luke", "John", "Acts",
        "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
        "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
        "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews",
        "James", "1 Peter", "2 Peter", "1 John", "2 John",
        "3 John", "Jude", "Revelation"
    ]

    private var currentBooks: [String] {
        selectedTestament == .old ? oldTestamentBooks : newTestamentBooks
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                HStack(spacing: 0) {
                    ForEach(Testament.allCases, id: \.self) { testament in
                        Button {
                            withAnimation {
                                haptic.impactOccurred()
                                selectedTestament = testament
                                expandedBooks.removeAll()
                            }
                        } label: {
                            Text(testament.rawValue)
                                .font(.custom("Palatino", size: 15))
                                .fontWeight(.medium)
                                .foregroundColor(selectedTestament == testament ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTestament == testament
                                    ? Color.blue
                                    : Color.clear
                                )
                        }
                    }
                }
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 24)
                .padding(.top, 8)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(currentBooks, id: \.self) { book in
                            VStack(alignment: .leading, spacing: 0) {

                                // Book row
                                HStack {
                                    Text(book)
                                        .font(.custom("Palatino", size: 17))
                                    Spacer()
                                    Image(systemName: expandedBooks.contains(book)
                                          ? "chevron.up"
                                          : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        haptic.impactOccurred()
                                        toggleBook(book)
                                    }
                                }

                                // Chapters grid
                                if let chapterCount = chaptersPerBook[book] {
                                    LazyVGrid(
                                        columns: Array(
                                            repeating: GridItem(.flexible(), spacing: 6),
                                            count: 5
                                        ),
                                        spacing: 12
                                    ) {
                                        ForEach(1...chapterCount, id: \.self) { chapter in
                                            Text("\(chapter)")
                                                .font(.system(size: 15))
                                                .frame(width: 65, height: 65)
                                                .background(Color(.systemGray5))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .onTapGesture {
                                                    haptic.impactOccurred()
                                                    selectedChapter = SelectedChapter(
                                                        book: book,
                                                        chapter: chapter
                                                    )
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 6)
                                    .padding(.bottom, 12)
                                    .opacity(expandedBooks.contains(book) ? 1 : 0)
                                    .frame(
                                        height: expandedBooks.contains(book) ? nil : 0
                                    )
                                    .clipped()
                                    .animation(
                                        .easeInOut(duration: 0.25),
                                        value: expandedBooks
                                    )
                                }
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .navigationDestination(item: $selectedChapter) { selection in
                ReadingView(
                    book: selection.book,
                    chapter: selection.chapter
                )
            }
            .onAppear {
                preloadChapterCounts()
            }
        }
    }

    private func toggleBook(_ book: String) {
        if expandedBooks.contains(book) {
            expandedBooks.remove(book)
        } else {
            expandedBooks.insert(book)
        }
    }

    private func preloadChapterCounts() {
        let dbQueue = DatabaseManager.shared.dbQueue

        try? dbQueue.read { db in
            for book in oldTestamentBooks + newTestamentBooks {
                if let count = try? Int.fetchOne(db, sql: """
                    SELECT COUNT(*) FROM chapters
                    WHERE book_id = (SELECT id FROM books WHERE name = ?)
                """, arguments: [book]) {
                    DispatchQueue.main.async {
                        chaptersPerBook[book] = count
                    }
                }
            }
        }
    }
}

