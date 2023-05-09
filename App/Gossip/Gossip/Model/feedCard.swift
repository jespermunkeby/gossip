import SwiftUI

struct FeedCard: View {
    let content: String
    let receivedDate: Date
    let isSaved: Bool
    let onSave: ()->Void
    let onDelete: ()->Void
    
    var screenSize: CGRect = UIScreen.main.bounds
    
    var body: some View {
        
        HStack {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 10) {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.black)

                Text("Received: \(receivedDate.formatted(.dateTime.year().month().day().hour().minute()))") // Add this line to display the received date
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                }
            }
            
            Button(action: {
                if isSaved {onDelete()} else {onSave()}
            
            }) {
                Image(systemName: "heart")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(isSaved ? .green : .gray)
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
