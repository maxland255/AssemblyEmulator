//
//  Parser.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import Foundation


class Asm80186Parser {
    
    private var parseFunction = false
    private var functionAvailable = [String]()
    
    func parse(_ sourceCode: String) -> ([Instruction], [String:Instruction]) {
        var instructions = [Instruction]()
        var functionsInstructions = [String:Instruction]()
        
//        Divides source code online
        let lines = sourceCode.components(separatedBy: .newlines)
        
        var linesRemoved = lines
        
        var currentFuncInstruction: Instruction? = nil
        
        for line in lines {
//            Ignore comment
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(";") else {
                continue
            }
            
//            Divide the line into words
            let components = line.components(separatedBy: CharacterSet(charactersIn: " \n")).filter { !$0.isEmpty }
            
//            Get if line is empty
            guard !components.isEmpty && !components.isOnlyTabs() else {
                continue
            }
            
            let opCodeString = components[0]
            let operands = Array(components.dropFirst().joined(separator: "").components(separatedBy: ",").filter { !$0.isEmpty })
            
            
            if self.parseFunction && !opCodeString.hasPrefix("\t"){
                self.parseFunction = false
                
                if let currentFuncInstruction = currentFuncInstruction{
                    if currentFuncInstruction.instructions?.isEmpty ?? true{
                        let error = NoFunctionInstruction(funcName: currentFuncInstruction.functionName ?? "", line: currentFuncInstruction.lineNumber.toUInt(), lineText: currentFuncInstruction.lineValue)
                        ConsoleLine.error(error: error)
                        return ([], [:])
                    }
                    
                    instructions.append(currentFuncInstruction)
                    
                    if functionsInstructions.contains(where: {$0.key == currentFuncInstruction.functionName}){
                        let error = TwoFunctionSameName(funcName: currentFuncInstruction.functionName ?? "", line: currentFuncInstruction.lineNumber.toUInt(), column: 0, endError: nil, lineText: currentFuncInstruction.lineValue)
                        ConsoleLine.error(error: error)
                        return ([], [:])
                    }
                    
                    functionsInstructions.updateValue(currentFuncInstruction, forKey: currentFuncInstruction.functionName!)
                }
                
                currentFuncInstruction = nil
            }
            
            if let opCode = parseOpCode(opCodeString) {
                if self.parseFunction, let parsedOperands = parseOperands(operands, line: line, lines: lines){
                    let lineIndex = linesRemoved.firstIndex(of: line)
                    
                    let instruction = Instruction(opcode: opCode, operands: parsedOperands, lineNumber: (lineIndex ?? -1) + 1, lineValue: line, function: false, functionName: nil, instructions: nil)
                    
                    if let lineIndex = lineIndex{
                        linesRemoved[lineIndex] += Date().ISO8601Format()
                    }
                    
                    currentFuncInstruction?.instructions?.append(instruction)                    
                }else if opCode == OpCode.funcLabel{
                    let lineIndex = linesRemoved.firstIndex(of: line)
                    
                    let funcName = self.getFunctionName(operand: opCodeString)
                    
                    self.parseFunction = true
                    
                    currentFuncInstruction = Instruction(opcode: opCode, operands: [], lineNumber: (lineIndex ?? -1) + 1, lineValue: line, function: true, functionName: funcName, instructions: [])
                    
                    self.functionAvailable.append(funcName)
                    
                    if let lineIndex = lineIndex{
                        linesRemoved[lineIndex] += Date().ISO8601Format()
                    }
                }else if let parsedOperands = parseOperands(operands, line: line, lines: lines) {
                    let lineIndex = linesRemoved.firstIndex(of: line)
                    
                    let instruction = Instruction(opcode: opCode, operands: parsedOperands, lineNumber: (lineIndex ?? -1) + 1, lineValue: line, function: false, functionName: nil, instructions: nil)
                    
                    if let lineIndex = lineIndex{
                        linesRemoved[lineIndex] += Date().ISO8601Format()
                    }
                    
                    instructions.append(instruction)
                }else{
                    return ([], [:])
                }
            }else{
                let opCodeStringFiltered = opCodeString.filter({ $0 != " " && $0 != "\t"})
                let column = opCodeString.filter({ $0 == " "}).count + opCodeString.filter({ $0 == "\t" }).count * 4
                let error = InvalidSyntaxe(line: (lines.firstIndex(of: line)?.toUInt() ?? 0) + 1, column: column.toUInt(), endError: opCodeStringFiltered.count.toUInt(), lineText: line)
                ConsoleLine.error(error: error)
                return ([], [:])
            }
        }
        
        if let currentFuncInstruction = currentFuncInstruction{
            if currentFuncInstruction.instructions?.isEmpty ?? true{
                let error = NoFunctionInstruction(funcName: currentFuncInstruction.functionName ?? "", line: currentFuncInstruction.lineNumber.toUInt(), lineText: currentFuncInstruction.lineValue)
                ConsoleLine.error(error: error)
                return ([], [:])
            }
            
            instructions.append(currentFuncInstruction)
            
            if functionsInstructions.contains(where: {$0.key == currentFuncInstruction.functionName}){
                let error = TwoFunctionSameName(funcName: currentFuncInstruction.functionName ?? "", line: currentFuncInstruction.lineNumber.toUInt(), column: 0, endError: nil, lineText: currentFuncInstruction.lineValue)
                ConsoleLine.error(error: error)
                return ([], [:])
            }
            
            functionsInstructions.updateValue(currentFuncInstruction, forKey: currentFuncInstruction.functionName!)
        }
        
        return (instructions, functionsInstructions)
    }
    
    private func parseOpCode(_ opCode: String, parseFunc: Bool? = nil) -> OpCode? {
        switch opCode.lowercased() {
//            Transfer
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")mov":
            return .mov
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")xchg":
            return .xchg
            
//            Arithemtic
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")add":
            return .add
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")sub":
            return .sub
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")div":
            return .div
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")mul":
            return .mul
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")inc":
            return .inc
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")dec":
            return .dec
            
//            Logic
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")neg":
            return .neg
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")not":
            return .not
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")and":
            return .and
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")or":
            return .or
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")xor":
            return .xor
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")shl":
            return .shl
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")shr":
            return .shr
        
//        Misc
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")nop":
            return .nop
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")lea":
            return .lea
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")int":
            return .int
            
//            Jumps
            
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")call":
            return .call
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")jmp":
            return .jmp
            
//            Stop
        case "\(parseFunc ?? self.parseFunction ? "\t" : "")hlt":
            return .hlt
        default:
            if opCode.hasSuffix(":"){
                return .funcLabel
            }else if parseFunc ?? self.parseFunction{
                return self.parseOpCode(opCode, parseFunc: false)
            }else{
                return nil
            }
        }
    }
    
    private func parseOperands(_ operandsString: [String], line: String, lines: [String]) -> [Operand]? {
        var operands = [Operand]()
        
        for operand in operandsString {
            if let register = X86Register(rawValue: operand.lowercased()){
                operands.append(.register(register))
            }else if let immediateValue = getImmediateValue(operand){
                operands.append(.immediate(immediateValue))
            }else if operand.hasPrefix("[") && operand.hasSuffix("]") {
                operands.append(.memory(operand))
            }else if self.functionAvailable.contains(operand){
                operands.append(.functions(operand))
            }else{
                let beforOperand = line.split(separator: operand).first ?? ""
                let column: UInt = beforOperand.count.toUInt() + beforOperand.filter({ $0 == "\t" }).count.toUInt() * 3
                let error = InvalidOperand(operand: operand, line: (lines.firstIndex(of: line)?.toUInt() ?? 0) + 1, column: column, endError: operand.count.toUInt(), lineText: line)
                ConsoleLine.error(error: error)
                return nil
            }
        }
        
        return operands
    }
    
    private func getFunctionName(operand: String) -> String{
        return operand.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "").replacingOccurrences(of: ":", with: "")
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
