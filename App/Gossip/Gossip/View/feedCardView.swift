//
//  feedCardView.swift
//  Gossip
//
import SwiftUI

struct FeedCardView: View {
    let post: FeedCard
    var screenSize: CGRect = UIScreen.main.bounds
    @ObservedObject var saveButtonViewModel = SaveButtonViewModel()
    var onSaveAction: (() -> Void)? // Add this line
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(post.title, systemImage: "arrowshape.right.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.black)
            
            HStack {
                Text(post.content)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.black)

                SaveButtonView(isFilled: saveButtonViewModel.isSaved, saveButtonAction: {
                    onSaveAction?() // Use the onSaveAction closure here
                    saveButtonViewModel.toggleSaved(for: post)
                })
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        //.frame(maxWidth: screenSize.width - 50)// Change the width of the card here
        .scenePadding()
    }
}

struct FeedCardView_Previews: PreviewProvider {
    static var post = FeedCard.sampleData[1]
    static var previews: some View {
        FeedCardView(post: post)
    }
}
