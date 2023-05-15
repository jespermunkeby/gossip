//
//  FeedCardView.swift
//  Feed
//
import SwiftUI

struct FeedCardView: View {
    let post: FeedCard
    var screenSize: CGRect = UIScreen.main.bounds
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(post.title, systemImage: "arrowshape.right.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(post.content)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .shadow(radius: 10)
                .frame(width: screenSize.width - 20)
        )
    }
}




struct FeedCardView_Previews: PreviewProvider {
    static var post = FeedCard.sampleData[1]
    static var previews: some View {
        FeedCardView(post: post)
    }
}
