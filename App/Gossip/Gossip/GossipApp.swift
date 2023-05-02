import Foundation
import SwiftUI

@main
struct GossipApp: App {
    @StateObject var coreDataViewModel = CoreDataViewModel()
    
    var body: some Scene {
        WindowGroup {
            let viewModel = BLEViewModel()
            ContentView(viewModel: viewModel)
                .environmentObject(coreDataViewModel)
        }
    }
}
