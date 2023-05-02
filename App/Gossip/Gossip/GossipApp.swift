//
//  CoreBluetoothLESampleApp.swift
//  CoreBluetoothLESample
//

import Foundation
import SwiftUI



@main
struct GossipApp: App {
    @StateObject var coreDataViewModel = CoreDataViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataViewModel)
        }
    }
}
