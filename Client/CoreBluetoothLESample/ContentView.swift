import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: BLEViewModel
    @State private var receivedText: String = ""

    var body: some View {
        VStack {
            Text("Received Text")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            TextEditor(text: $receivedText)
                .padding()
                .frame(height: 300)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)

            Button(action: {
                viewModel.connect()
            }, label: {
                Text("Connect")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            })
            .padding(.bottom)
        }
        .padding()
        .onReceive(viewModel.$receivedText) { newText in
            receivedText = newText
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: BLEViewModel())
    }
}
