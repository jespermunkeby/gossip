import SwiftUI

struct AddPostView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @State private var titleText: String = ""
    @State private var contentText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Post Title", text: $titleText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                TextField("Post Content", text: $contentText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Post")
            .navigationBarItems(trailing: Button(action: {
                savePost()
            }) {
                Text("Save")
            })
        }
    }

    private func savePost() {
        coreDataViewModel.saveMessage(title: titleText, content: contentText)
        titleText = ""
        contentText = ""
        presentationMode.wrappedValue.dismiss()
    }
}
