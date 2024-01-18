//
//  Instructions.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import Foundation


struct Instruction {
    let opcode: OpCode
    let operands: [Operand]
}

enum OpCode {
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

enum Operand: Equatable {
    case register(X86Register)  // Register name (e.g. "ax", "bx")
    case immediate(Int)    // Immediate value
    case memory(String)     // Memory address (e.g. "[ax]", "[bx+si]")
}
