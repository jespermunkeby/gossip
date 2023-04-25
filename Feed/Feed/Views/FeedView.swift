//  Feed.swift
//  Feed
//

import SwiftUI

struct FeedView: View {
    let posts: [FeedCard]
    
    var body: some View {
        ZStack {
            Color(red: 204/255, green: 225/255, blue: 218/255).ignoresSafeArea()
            VStack {
                //List(posts, id: \.title) { post in
                    //CardView(post: post)
                //}
                ForEach(posts, id: \.title) { post in
                    FeedCardView(post: post)
                }
                .padding(.vertical, 10)

                .scrollContentBackground(.hidden)
                
            }
        }

    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(posts: FeedCard.sampleData)
    }
}
