//
//  X86Error.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 14/02/2024.
//

import Foundation
import AppKit


class x86Error{
    private let details: String
    private let line: UInt
    private let column: UInt
    private let endError: UInt?
    private let lineText: String
    let program: String
    
    init(details: String, line: UInt, column: UInt, endError: UInt?, lineText: String, program: String? = nil) {
        self.details = details
        self.line = line
        self.column = column
        self.lineText = lineText
        self.endError = endError
        self.program = program ?? "Asm Intel x86"
    }
    
    func getErrorString() -> String{
        var result = "\(self.details)   Line: \(self.line)\n"
        result += "\(self.lineText)\n"
        
        for _ in 0..<self.column{
            result += " "
        }
        
        for _ in 0..<(self.endError ?? (self.lineText.count.toUInt() - self.column)){
            result += "^"
        }
        
        return result
    }
}


class InvalidSyntaxe: x86Error{
    init(line: UInt, column: UInt, endError: UInt?, lineText: String, program: String? = nil) {
        super.init(details: "Invalid syntaxe", line: line, column: column, endError: endError, lineText: lineText, program: program)
    }
}


class NoFunctionInstruction: x86Error{
    init(funcName: String, line: UInt, lineText: String, program: String? = nil) {
        super.init(details: "No instruction found in function: \(funcName)", line: line, column: 0, endError: lineText.count.toUInt() - 1, lineText: lineText, program: program)
    }
}


class InvalidOperand: x86Error{
    init(operand: String, line: UInt, column: UInt, endError: UInt?, lineText: String, program: String? = nil) {
        super.init(details: "Invalid operand: \(operand)", line: line, column: column, endError: endError, lineText: lineText, program: program)
    }
}


class NotSupported: x86Error{
    init(instruction: String, line: UInt, column: UInt, endError: UInt?, lineText: String, program: String? = nil) {
        super.init(details: "Instruction \(instruction) is not supported in \(NSApplication.appName)", line: line, column: column, endError: endError, lineText: lineText, program: program)
    }
}


class FunctionNotFound: x86Error{
    init(funcName: String, line: UInt, column: UInt, endError: UInt?, lineText: String, program: String? = nil) {
        super.init(details: "Function \(funcName) is not found", line: line, column: column, endError: endError, lineText: lineText, program: program)
    }
}


class TwoFunctionSameName: x86Error{
    init(funcName: String, line: UInt, column: UInt, endError: UInt?, lineText: String, program: String? = nil) {
        super.init(details: "Two functions with the same name is not allowed (\(funcName))", line: line, column: column, endError: endError, lineText: lineText, program: program)
    }
}
