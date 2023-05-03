import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: BLEViewModel
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @State private var messages: [FeedCard] = FeedCard.sampleData
    @State private var isShowingSavedMessages = false
    @State private var isShowingAddPostView = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack{
                        HeaderView(showSettings: .constant(true))
                    ScrollView {
                        VStack(spacing: 20) {
                            Button(action: {
                                isShowingSavedMessages.toggle()
                            }) {
                                Text("View Saved Messages")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .sheet(isPresented: $isShowingSavedMessages) {
                                SavedMessagesView()
                                    .environmentObject(coreDataViewModel)
                            }
                            ForEach(messages.indices, id: \.self) { index in
                                let post = FeedCard(
                                    title: "Message \(index + 1) from hub",
                                    content: messages[index].content,
                                    saveButtonViewModel: SaveButtonViewModel()
                                )
                                FeedCardView(post: post, onSaveAction: {
                                    coreDataViewModel.saveMessage(title: post.title, content: post.content)
                                })
                            }
                        }
                        .padding(.horizontal, min(geometry.safeAreaInsets.leading, geometry.safeAreaInsets.trailing) + 20)
                        .padding(.vertical, 20)
                        
                        if messages.isEmpty {
                            VStack {
                                ProgressView()
                                    .scaleEffect(2.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                Text("Looking for gossip 🤔")
                                    .font(.title)
                                    .foregroundColor(.green)
                                    .padding()
                            }
                            .padding()
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .frame(width: min(geometry.size.width, geometry.size.height))
                        }
                    }
                }
                    Button(action: {
                        isShowingAddPostView.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $isShowingAddPostView) {
                        AddPostView()
                            .environmentObject(coreDataViewModel)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                .onReceive(viewModel.$receivedText) { content in
                    if !content.isEmpty {
                        let newFeedCard = FeedCard(
                            title: "Message \(messages.count + 1) from hub",
                            content: content,
                            saveButtonViewModel: SaveButtonViewModel()
                        )
                        messages.append(newFeedCard)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: BLEViewModel())
    }
}
