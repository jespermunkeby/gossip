import SwiftUI

struct AddPostView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @State private var titleText: String = ""
    @State private var contentText: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0

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
        coreDataViewModel.saveMessage(title: titleText, content: contentText, time: Date(), latitude: latitude, longitude: longitude)
        titleText = ""
        contentText = ""
        latitude = 0.0
        longitude = 0.0
        presentationMode.wrappedValue.dismiss()
    }
}
