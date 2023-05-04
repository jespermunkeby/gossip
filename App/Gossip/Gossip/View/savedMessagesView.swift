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
                        saveButtonViewModel: SaveButtonViewModel()
                    )

                    FeedCardView(post: post, isSaved: .constant(true)) { isSaved in
                        if !isSaved {
                            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                                deleteMessages(at: [index])
                            }
                        }
                    }
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
