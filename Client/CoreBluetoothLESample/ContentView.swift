import SwiftUI

struct MessageCard: View {
    let title: String
    let content: String
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
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: BLEViewModel
    @State private var messages: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if (messages.isEmpty) {
                    // Show a loading screen until at least one message is received
                    Text("Looking for posts...🤔")
                        .font(.title2)
                        .foregroundColor(.gray)
                }else {
                    ForEach(messages.indices, id: \.self) { index in
                        MessageCard(title: "Message \(index + 1) from hub", content: messages[index])
                    }
                }
            }
        }
        .padding()
        .onReceive(viewModel.$receivedText) { newText in
            if !newText.isEmpty {
                messages.append(newText)
            }
        }

    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: BLEViewModel())
    }
}
