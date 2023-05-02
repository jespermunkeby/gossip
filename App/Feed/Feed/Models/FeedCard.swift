//
//  FeedCard.swift
//  Feed
//

import Foundation

struct FeedCard {
    var title: String
    var content: String
}

extension FeedCard {
    static let sampleData: [FeedCard] =
    [
        FeedCard(title: "First Post",
                 content: "This is the first post. Here is some more test just to test how stuff looks. "),
        FeedCard(title: "Second Post",
                 content: "This is the second post"),
        FeedCard(title: "Third Post",
                 content: "This is the third post")
    ]
}
