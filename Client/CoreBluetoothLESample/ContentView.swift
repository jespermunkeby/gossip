import SwiftUI

struct MessageCard: View {
    let title: String
    let content: String
    let action: (() -> Void)?
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

                if let action = action {
                    Button(action: action) {
                        Text("Save")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
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
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @State private var messages: [String] = []
    @State private var isShowingSavedMessages = false

    var body: some View {
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
                    MessageCard(title: "Message \(index + 1) from hub", content: messages[index], action: {
                        // Save the message when the "Save" button is tapped
                        coreDataViewModel.saveMessage(title: "Message \(index + 1) from hub", content: messages[index])
                    })
                }
            }
        }
        .padding()
        .onReceive(viewModel.$receivedText) { newText in
            messages.append(newText)
        }
    }
}

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: BLEViewModel())
    }
}
