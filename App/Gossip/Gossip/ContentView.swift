import SwiftUI

struct ContentView: View {
    @ObservedObject var model = ContentViewModel()
    @State var savedView = false
    @State var createView = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack{
                        HeaderView(showSettings: .constant(true), isContentView: .constant(true))

                        ScrollView {
                            VStack() {
                                ForEach(model.feedMessages, id: \.self) { message in
                                    FeedCard(
                                        content: String(data: message.content, encoding: .utf8)!,
                                        receivedDate: message.pickupTime,
                                        isSaved: model.isSaved(message: message),
                                        onSave: {model.saveMessage(message: message)},
                                        onDelete: {model.deleteMessage(message: message)}
                                    )
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
                                model.setViewMode(viewMode: ViewMode.saved)
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
                            .sheet(isPresented: $savedView) {
                                SavedMessagesView()
                            }

                            Button(action: {
                                model.setViewMode(viewMode: ViewMode.create)
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
                            .sheet(isPresented: $createView) {
                                AddPostView()
                            }
                        }
                    }
                }
                .onReceive(model.$viewMode) { viewMode in
                    if(viewMode == ViewMode.create){
                        savedView = false
                        createView = true
                    } else if (viewMode == ViewMode.saved){
                        savedView = true
                        createView = false
                    }
                }
                
                /*
                .onReceive(BluetoothManager.shared.$messages) { msgs in
                    let sortedArray = Array(msgs).sorted { $0.pickupTime > $1.pickupTime }
                    messages = sortedArray.enumerated().map { index, msg in
                        let content = String(decoding: msg.content, as: UTF8.self)
                        return FeedCard(
                            title: "Message \(index + 1) from hub",
                            content: content,
                            receivedDate: msg.pickupTime,
                            saveButtonViewModel: SaveButtonViewModel()
                        )
                    }
                }
                 */


                /*
                //TODO: Implement in model instead!!!!
                .onReceive(BluetoothManager.shared.$initialized_peripheral) { ready in
                    if ready{
                        BluetoothManager.shared.cycle()
                    }
                }
                 */
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
