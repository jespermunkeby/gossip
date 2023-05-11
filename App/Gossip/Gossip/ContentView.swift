import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @State private var messages: [FeedCard] = []
    @State private var isShowingSavedMessages = false
    @State private var isShowingAddPostView = false
    @State private var savedMessages: [FeedCard] = []

    var allMessages: [FeedCard] {
        return messages + savedMessages
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack{
                        HeaderView(showSettings: .constant(true), isContentView: .constant(true), messages: allMessages)

                        ScrollView {
                            VStack() {
                                ForEach(messages.indices, id: \.self) { index in
                                    let post = FeedCard(
                                        title: "Message \(index + 1)",
                                        content: messages[index].content,
                                        receivedDate: messages[index].receivedDate,
                                        latitude: messages[index].latitude,
                                               longitude: messages[index].longitude,
                                        saveButtonViewModel: SaveButtonViewModel()
                                    )
                                    FeedCardView(post: post, onSaveAction: { isSaved in
                                        if isSaved {
                                            coreDataViewModel.saveMessage(title: post.title, content: post.content, time: post.receivedDate, latitude: post.latitude, longitude: post.longitude)
                                        } else {
                                            // Find the corresponding saved message and remove it
                                            if let message = coreDataViewModel.fetchMessages().first(where: { $0.title == post.title && $0.content == post.content }) {
                                                coreDataViewModel.deleteMessage(message)
                                            }
                                        }
                                    })
                                }
                                
                            }
                            .padding(.horizontal, min(geometry.safeAreaInsets.leading, geometry.safeAreaInsets.trailing) + 20)
                            .padding(.vertical, 20)
                        }
                    }
                    VStack {
                        Spacer()

                        HStack(spacing: -20) {
                            Spacer()

                            Button(action: {
                                isShowingSavedMessages = true
                            }) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color(#colorLiteral(red: 0.7960784314, green: 0.8980392157, blue: 0.8745098039, alpha: 1)))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: "heart")
                                        .foregroundColor(.black)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .padding()
                            .sheet(isPresented: $isShowingSavedMessages) {
                                SavedMessagesView()
                                    .environmentObject(coreDataViewModel)
                            }

                            Button(action: {
                                isShowingAddPostView = true
                            }) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color(#colorLiteral(red: 0.7960784314, green: 0.8980392157, blue: 0.8745098039, alpha: 1)))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "plus")
                                        .foregroundColor(.black)
                                        .frame(width: 50, height: 50)
                                }
                            }
                            .padding()
                            .sheet(isPresented: $isShowingAddPostView) {
                                AddPostView()
                                    .environmentObject(coreDataViewModel)
                            }
                        }
                    }
                }
                .onAppear {
                               // Fetch saved messages from CoreData when the view appears
                               let fetchedMessages = coreDataViewModel.fetchMessages()
                               savedMessages = fetchedMessages.map { message in
                                   FeedCard(
                                       title: message.title ?? "",
                                       content: message.content ?? "",
                                       receivedDate: message.timestamp ?? Date(),
                                       latitude: message.latitude,
                                       longitude: message.longitude,
                                       saveButtonViewModel: SaveButtonViewModel()
                                   )
                               }
                           }
                .onReceive(BluetoothManager.shared.$messages) { msgs in
                    let sortedArray = Array(msgs).sorted { $0.pickupTime > $1.pickupTime }
                    messages = sortedArray.enumerated().map { index, msg in
                        let content = String(decoding: msg.content, as: UTF8.self)
                        return FeedCard(
                            title: "Message \(index + 1) from hub",
                            content: content,
                            receivedDate: msg.pickupTime,
                            latitude: msg.location.latitude,
                            longitude: msg.location.longitude,
                            saveButtonViewModel: SaveButtonViewModel()
                        )
                    }
                }


                //TODO: chaeck both init
                .onReceive(BluetoothManager.shared.$initialized_peripheral) { ready in
                    if ready{
                        BluetoothManager.shared.cycle()
                    }
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
