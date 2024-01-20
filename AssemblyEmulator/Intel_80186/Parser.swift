//
//  Parser.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import Foundation


class Asm80186Parser {
    
    func parse(_ sourceCode: String) -> [Instruction] {
        var instructions = [Instruction]()
        
//        Divides source code online
        let lines = sourceCode.components(separatedBy: .newlines)
        
        var linesRemoved = lines
        
        for line in lines {
//            Ignore comment
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(";") else {
                continue
            }
            
//            Divide the line into words
            let components = line.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            
//            Get if line is empty
            guard !components.isEmpty else {
                continue
            }
            
            let opCodeString = components[0]
            let operands = Array(components.dropFirst().joined(separator: "").components(separatedBy: ",").filter { !$0.isEmpty })
            
            if let opCode = parseOpCode(opCodeString) {
                if let parsedOperands = parseOperands(operands) {
                    let lineIndex = linesRemoved.firstIndex(of: line)
                    
                    let instruction = Instruction(opcode: opCode, operands: parsedOperands, lineNumber: (lineIndex ?? -1) + 1, lineValue: line)
                    
                    if let lineIndex = lineIndex{
                        linesRemoved[lineIndex] += Date().ISO8601Format()
                    }
                    
                    instructions.append(instruction)
                }else{
                    return []
                }
            }else{
                ConsoleLine.shared.appendLine("Asm Intel x86", "Error to parse instruction: \(line)", color: .red)
                return []
            }
        }
        
        return instructions
    }
    
    private func parseOpCode(_ opCode: String) -> OpCode? {
        switch opCode.lowercased() {
//            Transfer
        case "mov":
            return .mov
            
//            Arithemtic
        case "add":
            return .add
        case "sub":
            return .sub
        case "div":
            return .div
        case "mul":
            return .mul
        case "inc":
            return .inc
        case "dec":
            return .dec
            
//            Logic
        case "neg":
            return .neg
        case "not":
            return .not
        case "and":
            return .and
        case "or":
            return .or
        case "xor":
            return .xor
            
//            Stop
        case "htl":
            return .hlt
        default:
            return nil
        }
    }
    
    private func parseOperands(_ operandsString: [String]) -> [Operand]? {
        var operands = [Operand]()
        
        for operand in operandsString {
            if let register = X86Register(rawValue: operand.lowercased()){
                operands.append(.register(register))
            }else if let immediateValue = getImmediateValue(operand){
                operands.append(.immediate(immediateValue))
            }else if operand.hasPrefix("[") && operand.hasSuffix("]") {
                operands.append(.memory(operand))
            }else{
                ConsoleLine.shared.appendLine("Asm Intel x86", "Error to parse operand: \(operand)", color: .red)
                return nil
            }
        }
        
        return operands
    }
    
    private func getImmediateValue(_ value: String) -> Int?{
        if value.hasSuffix("b"){
            return Int(value.dropLast(), radix: 2)
        }else if value.hasSuffix("h"){
            return Int(value.dropLast(), radix: 16)
        }else{
            return Int(value)
        }
    }
}
