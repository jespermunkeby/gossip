import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        BluetoothManager.shared.cycle()
    }
}

@main
struct GossipApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let coreDataViewModel = CoreDataViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataViewModel)
        }
    }
}
