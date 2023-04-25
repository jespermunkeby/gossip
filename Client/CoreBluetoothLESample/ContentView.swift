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
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(messages.indices, id: \.self) { index in
                            MessageCard(title: "Message \(index + 1) from hub", content: messages[index])
                        }
                    }
                    .padding()
                }
                .padding()
                
                if (messages.isEmpty) {
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
        .onReceive(viewModel.$receivedText) { newText in
            if !newText.isEmpty {
                messages.append(newText)
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: BLEViewModel()
            )
    }
}
