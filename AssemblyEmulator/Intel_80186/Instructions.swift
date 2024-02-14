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
    let function: Bool
    let functionName: String?
    var instructions: [Instruction]?
}

enum OpCode: String, CaseIterable {
//    Transfer
    case mov
    case xchg
    
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
    case shl
    case shr
    
//    Misc
    case nop
    case lea
    case int
    
//    Jumps
    case call
    case jmp
    
//    Stop
    case hlt
    
//    Functions
    case funcLabel
}

extension OpCode{
    static func values() -> [String]{
        return self.allCases.map { $0.rawValue }
    }
    
    func getRegister(_ processor: ProcessorType? = nil) -> X86Register?{
        if processor == nil{
            return nil
        }else{
            return X86Register.ax
        }
    }
}

enum Operand: Equatable {
    case register(X86Register)  // Register name (e.g. "ax", "bx")
    case immediate(Int)    // Immediate value
    case memory(String)     // Memory address (e.g. "[ax]", "[bx+si]")
    case functions(String)  // Function name (e.g. "main", "test")
}
