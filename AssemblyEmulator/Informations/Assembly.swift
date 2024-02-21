//
//  Assembly.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 21/02/2024.
//

import SwiftUI

struct Assembly: View {
    
    @State private var assemblyType: AssemblyType = .intel_x86
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("No content for the moment")
                    .font(.title)
                    .padding()
            }
        }.frame(width: 1000, height: 550)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("About: \(assemblyType.rawValue)") {
                        ForEach(AssemblyType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                assemblyType = type
                            }.disabled(assemblyType == type)
                        }
                    }
                }
            }
    }
    
    private enum AssemblyType: String, CaseIterable{
        case intel_x86 = "Intel x86"
        case micro_language = "Micro language"
        case custom_assembly = "Custom assembly"
    }
}

#Preview {
    Assembly()
}
