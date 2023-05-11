import SwiftUI

struct FeedCard: View {
    let title: String
    let content: String
    let receivedDate: Date
    let latitude: Double
    let longitude: Double
    @ObservedObject var saveButtonViewModel: SaveButtonViewModel
    @State private var isShowingContent = false
    
    var body: some View {
        VStack {
            Button(action: {
                isShowingContent.toggle()
            }, label: {
                Text(title)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(8)
            })

            if isShowingContent {
                Text(content)
                    .padding()

                SaveButtonView(isFilled: saveButtonViewModel.isSaved, saveButtonAction: { saveButtonViewModel.toggleSaved(for: self) })
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}



extension FeedCard {
    static let sampleData: [FeedCard] = [
        FeedCard(
            title: "First Post",
            content: "This is the first post. Here is some more test just to test how stuff looks.",
            receivedDate: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            saveButtonViewModel: SaveButtonViewModel()
        ),
        FeedCard(
            title: "Second Post",
            content: "This is the second post",
            receivedDate: Date(),
            latitude: 51.5074,
            longitude: -0.1278,
            saveButtonViewModel: SaveButtonViewModel()
        ),
        FeedCard(
            title: "Third Post",
            content: "This is the third post",
            receivedDate: Date(),
            latitude: 40.7128,
            longitude: -74.0060,
            saveButtonViewModel: SaveButtonViewModel()
        )
    ]
}
