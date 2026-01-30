//
//  SearchView.swift
//  bible_ios
//
//  Created by Caleb Chiang on 2026-01-29.
//

import SwiftUI

struct SearchView: View {
    @State private var query = ""
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    @State private var searchTrigger = UUID()

    let tags = [
        "anxiety",
        "encouragement",
        "forgiveness",
        "healing",
        "hope",
        "peace",
        "stress"
    ].sorted()

    let famousVerses = [
        "John 3:16",
        "Psalm 23:1",
        "Philippians 4:13",
        "Genesis 1:1",
        "Romans 8:28"
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Search Bar (always visible)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search...", text: $query)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        haptic.impactOccurred()
                        query = query.trimmingCharacters(in: .whitespacesAndNewlines)
                        searchTrigger = UUID() // Triggers a new SearchResultsView
                    }

                if !query.isEmpty {
                    Button(action: {
                        haptic.impactOccurred()
                        query = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 16)

            if query.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        Text("Popular Searches:")
                            .font(.custom("Palatino", size: 17))
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        ForEach(tags, id: \.self) { tag in
                            Button {
                                haptic.impactOccurred()
                                query = tag
                            } label: {
                                row(text: tag.capitalized)
                            }

                            if tag == "stress" {
                                ForEach(famousVerses, id: \.self) { verse in
                                    Button {
                                        haptic.impactOccurred()
                                        query = verse
                                    } label: {
                                        row(text: verse)
                                    }
                                }
                            }
                        }

                        Spacer().frame(height: 32)
                    }
                }
            } else {
                SearchResultsView(query: query)
                    .id(searchTrigger)
            }
        }
    }

    private func row(text: String) -> some View {
        HStack(spacing: 12) {
            Text("•")
                .foregroundColor(.secondary)

            Text(text)
                .font(.custom("Palatino", size: 17))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal)
    }
}

