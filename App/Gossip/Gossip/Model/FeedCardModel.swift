//
//  FeedCardModel.swift
//  Gossip
//
//  Created by abc on 2023-05-04.
//

import Foundation

struct FeedCardModel: Hashable, Identifiable {
    let id = UUID()
    let title: String
    let content: String
    
    static var sampleData: [FeedCardModel] = [
        FeedCardModel(title: "Title 1", content: "This is some sample content for the first post."),
        FeedCardModel(title: "Title 2", content: "This is some sample content for the second post."),
        FeedCardModel(title: "Title 3", content: "This is some sample content for the third post.")
    ]
}
