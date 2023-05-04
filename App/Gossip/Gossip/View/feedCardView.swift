import SwiftUI

struct FeedCardView: View {
    let post: FeedCard
    var screenSize: CGRect = UIScreen.main.bounds
    @ObservedObject var saveButtonViewModel = SaveButtonViewModel()
    var onSaveAction: ((Bool) -> Void)? // Update this line
    
    var body: some View {
        HStack {
        VStack(alignment: .leading, spacing: 15) {
            Label(post.title, systemImage: "arrowshape.right.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.black)
            
 
                VStack(alignment: .leading, spacing: 10) {
                    Text(post.content)
                        .font(.subheadline)
                        .foregroundColor(.black)

                    Text("Received: \(post.receivedDate.formatted(.dateTime.year().month().day().hour().minute()))") // Add this line to display the received date
                        .font(.footnote)
                        .foregroundColor(.gray)
                }


            }
            SaveButtonView(isFilled: saveButtonViewModel.isSaved, saveButtonAction: {
                saveButtonViewModel.toggleSaved(for: post)
                onSaveAction?(saveButtonViewModel.isSaved) // Use the onSaveAction closure here
            })
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        .scenePadding()
    }
}



struct FeedCardView_Previews: PreviewProvider {
    static var post = FeedCard.sampleData[1]
    static var previews: some View {
        FeedCardView(post: post)
    }
}
