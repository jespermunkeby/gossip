//
//  CoreBluetothLESampleApp.swift
//  CoreBluetoothLESample
//
//  Created by Jesper Munkeby on 2023-04-24.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

@main
struct CoreBluetoothLESampleApp: App {
    var body: some Scene {
        WindowGroup {
            let viewModel = BLEViewModel()
            ContentView(viewModel: viewModel)
        }
    }
}
