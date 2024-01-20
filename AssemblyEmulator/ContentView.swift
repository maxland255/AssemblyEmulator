//
//  ContentView.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import SwiftUI

struct ContentView: View {
    
    @State var emulatorType: EmulatorType = .intel_x86
    
    @State var parser = Asm80186Parser()
    @ObservedObject var interpreter = Asm80186Interpreter()
    
    @State var sourceCode = ""
    
    var body: some View {
        NavigationStack {
            switch emulatorType {
            case .intel_x86:
                Intel_x86_80186_UI()
            }
        }.toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    ForEach(EmulatorType.allCases, id: \.self) { emulator in
                        Button(emulator.rawValue) {
                            emulatorType = emulator
                        }.disabled(emulator == emulatorType)
                    }
                } label: {
                    Text(emulatorType.rawValue)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
