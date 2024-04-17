//
//  Configuration.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/04/2024.
//

import Foundation


struct Configuration {
    var section: IntelX86Section?
    var global: String?
}

enum IntelX86Section: String {
    case text
    case data
    case bss
}
