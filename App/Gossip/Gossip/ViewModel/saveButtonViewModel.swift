import Foundation

class SaveButtonViewModel: ObservableObject {
    @Published var isSaved = false
    
    func toggleSaved(for post: FeedCard) {
        isSaved.toggle()
        
        if isSaved {
            print("Post saved: \(post.content)")
        } else {
            print("Post unsaved: \(post.content)")
        }
    }
}
