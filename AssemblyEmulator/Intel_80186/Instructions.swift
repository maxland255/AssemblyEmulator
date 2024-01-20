//
//  Instructions.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import Foundation


struct Instruction {
    let id = UUID().uuidString
    let opcode: OpCode
    let operands: [Operand]
    let lineNumber: Int
    let lineValue: String
}

enum OpCode: String, CaseIterable {
//    Transfer
    case mov
    
//    Arithmetic
    case add
    case sub
    case div
    case mul
    case inc
    case dec
    
//    Logic
    case neg
    case not
    case and
    case or
    case xor
    
//    Stop
    case hlt
}

extension OpCode{
    static func values() -> [String]{
        return self.allCases.map { $0.rawValue }
    }
}

enum Operand: Equatable {
    case register(X86Register)  // Register name (e.g. "ax", "bx")
    case immediate(Int)    // Immediate value
    case memory(String)     // Memory address (e.g. "[ax]", "[bx+si]")
}
