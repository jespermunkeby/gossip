import SwiftUI

struct FeedCardView: View {
    let post: FeedCard
    var screenSize: CGRect = UIScreen.main.bounds
    
    var body: some View {
        HStack {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 10) {
                Text(post.content)
                    .font(.subheadline)
                    .foregroundColor(.black)

                Text("Received: \(post.receivedDate.formatted(.dateTime.year().month().day().hour().minute()))") // Add this line to display the received date
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                
            }


            }
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
