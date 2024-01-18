//
//  VisualEffect.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import Foundation
import SwiftUI


struct VisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        return NSVisualEffectView()
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}
