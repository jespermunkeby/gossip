import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @State private var messages: [FeedCard] = FeedCard.sampleData
    @State private var isShowingSavedMessages = false
    @State private var isShowingAddPostView = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
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
                                title: "Message \(index + 1)",
                                content: messages[index].content,
                                saveButtonViewModel: SaveButtonViewModel()
                            )
                            FeedCardView(post: post, onSaveAction: { isSaved in
                                if isSaved {
                                    coreDataViewModel.saveMessage(title: post.title, content: post.content)
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
            .onReceive(BluetoothManager.shared.$sharedData) { sharedData in
                messages = sharedData.enumerated().map { index, data in
                    let content = String(decoding: data, as: UTF8.self)
                    return FeedCard(
                        title: "Message \(index + 1) from hub",
                        content: content,
                        saveButtonViewModel: SaveButtonViewModel()
                    )
                }
            }
            .onReceive(BluetoothManager.shared.$initialized) { ready in
                if ready{
                    BluetoothManager.shared.cycle(scanDuration: 10, messageInterval: 0.1, cycleDuration: 15)
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


//Uncomment this block to test how the feed looks.
/*struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(FeedCard.sampleData, id: \.title) { card in
                    FeedCardView(post: card)
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/
    //Old savedMessages
    /*
    struct SavedMessagesView: View {
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject var coreDataViewModel: CoreDataViewModel
        
        var body: some View {
            NavigationView {
                List {
                    ForEach(coreDataViewModel.fetchMessages(), id: \.self) { message in
                        MessageCard(title: message.title ?? "", content: message.content ?? "", action: nil)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            coreDataViewModel.deleteMessage(coreDataViewModel.fetchMessages()[index])
                        }
                    }
                }
                .navigationTitle("Saved Messages")
                .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back")
                }, trailing: EditButton())
            }
        }
    }
     */
/*
struct SavedMessagesView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(coreDataViewModel.fetchMessages(), id: \.self) { message in
                    let post = FeedCard(
                        title: message.title ?? "",
                        content: message.content ?? "",
                        saveButtonViewModel: SaveButtonViewModel()
                    )
                    FeedCardView(post: post)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        coreDataViewModel.deleteMessage(coreDataViewModel.fetchMessages()[index])
                    }
                }
            }
            .navigationTitle("Saved Messages")
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Back")
            }, trailing: EditButton())
        }
    }
}
*/
