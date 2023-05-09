import SwiftUI

struct SavedMessagesView: View {
    @Environment(\.dismiss) var dismiss
    var coreDataViewModel: CoreDataViewModel = CoreDataViewModel()
    @State private var messages: [MessageModel] = []

    var body: some View {
        NavigationView {
            List {
                //TODO: refactor this to use model
                ForEach(coreDataViewModel.fetchMessages(), id: \.self) { message in
                    let post = FeedCard(
                        content: message.content ?? "",
                        receivedDate: message.timestamp ?? Date(),
                        isSaved: true,
                        onSave: {},
                        onDelete: {}
                    )
                    FeedCardView(post: post)
                }
                .onDelete(perform: deleteMessages)
            }
            .navigationTitle("Saved Messages")
            .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                Text("Back")
            }, trailing: EditButton())
            .onAppear {
                messages = coreDataViewModel.fetchMessages()
            }
        }
    }

    private func deleteMessages(at offsets: IndexSet) {
        offsets.forEach { index in
            let message = messages[index]
            coreDataViewModel.deleteMessage(message)
        }
        messages = coreDataViewModel.fetchMessages()
    }
}

