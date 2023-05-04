import SwiftUI

struct SaveButtonView: View {
    @Binding var isFilled: Bool
    var saveButtonAction: () -> Void
    
    var body: some View {
        Button(action: {
            isFilled.toggle()
            saveButtonAction()
        }) {
            Image(systemName: "heart")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isFilled ? .green : .gray)
        }
    }
}

