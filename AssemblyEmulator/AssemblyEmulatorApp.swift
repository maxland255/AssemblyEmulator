//
//  AssemblyEmulatorApp.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import SwiftUI

@main
struct AssemblyEmulatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, idealWidth: 1000, maxWidth: .infinity, minHeight: 550, idealHeight: 550, maxHeight: .infinity)
        }.defaultSize(CGSize(width: 1000, height: 550))
    }
}
