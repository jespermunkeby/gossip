import SwiftUI

struct SavedMessagesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @State private var messages: [MessageModel] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(coreDataViewModel.fetchMessages(), id: \.self) { message in
                    let post = FeedCard(
                        title: message.title ?? "",
                        content: message.content ?? "",
                        receivedDate: message.timestamp ?? Date(),
                        latitude: message.latitude,
                        longitude: message.longitude,
                        saveButtonViewModel: SaveButtonViewModel()
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

