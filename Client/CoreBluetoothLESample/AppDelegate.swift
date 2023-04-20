import UIKit
import SwiftUI
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create the BLEViewModel instance
        let viewModel = BLEViewModel()

        // Create the SwiftUI ContentView with the BLEViewModel instance
        let contentView = ContentView(viewModel: viewModel)

        // Set up the window and the root view controller
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()

        return true
    }
}

