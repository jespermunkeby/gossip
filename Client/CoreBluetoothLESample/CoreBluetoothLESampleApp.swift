//
//  CoreBluetoothLESampleApp.swift
//  CoreBluetoothLESample
//
//  Created by Abbas Alubeid on 2023-04-24.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import SwiftUI



@main
struct CoreBluetoothLESampleApp: App {
    @StateObject var coreDataViewModel = CoreDataViewModel()
    
    var body: some Scene {
        WindowGroup {
            let viewModel = BLEViewModel()
            ContentView(viewModel: viewModel)
                .environmentObject(coreDataViewModel)
        }
    }
}
