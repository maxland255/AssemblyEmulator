//
//  Interpreter.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import Foundation
import SwiftUI


class Asmx86Interpreter: ObservableObject {
    @Published var registers = [X86Register:Register]()
    @Published var stepNumber: UInt = 0
    @Published var maximumStep: UInt = 0
    @Published var funcInstructionCount: UInt = 0
    @Published var executeFuncInstructions: UInt = 0
    @Published var executeInstructions: UInt = 0
    @Published var skipedInstruction: UInt = 0
    @Published var runed = false
    @Published var currentInstruction: Instruction?
    
    var strict: Bool = false
    var instructions = [Instruction]()
    var funcInstructions = [String:Instruction]()
    var configuration: Configuration?
    var call_address: stack_t = stack_t()
    
    func interpret(_ instructions: [Instruction], _ funcInstructions: [String:Instruction], configuration: Configuration, strict: Bool = false) {
        self.strict = strict
        self.runed = true
        self.configuration = configuration
                
        if configuration.global == nil {
            let error = x86Error(details: "The global operand not found", line: 0, column: 0, endError: nil, lineText: "")
            ConsoleLine.error(error: error)
            ConsoleLine.error("Asm Intel x86", "Stopping...")
            self.runed = false
            return
        }else if configuration.section == nil {
            let error = x86Error(details: "The section operand not found", line: 0, column: 0, endError: nil, lineText: "")
            ConsoleLine.error(error: error)
            ConsoleLine.error("Asm Intel x86", "Stopping...")
            self.runed = false
            return
        }else if funcInstructions[configuration.global!] == nil {
            let error = MainFunctionNotFound(funcName: configuration.global!)
            ConsoleLine.error(error: error)
            ConsoleLine.error("Asm Intel x86", "Stopping...")
            self.runed = false
            return
        }
        
        for instruction in instructions {
            if instruction.function && instruction.functionName != self.configuration?.global! {
                continue
            }
            
            let result_execute = instruction.opcode == .funcLabel && instruction.functionName == self.configuration?.global! ? self.executeFunction(funcInstructions, functionName: (self.configuration?.global!)!) : self.executeInstruction(instruction, funcInstructions)
            
            if result_execute == nil{
                return
            }else if result_execute == false{
                ConsoleLine.error("Asm Intel x86", "Stopping...")
                self.runed = false
                return
            }
        }
        
        ConsoleLine.info("Asm Intel x86", "Stopping...")
        self.runed = false
    }
    
    ///
    ///Run interpreter step by step
    ///
    func interpretStepByStep(_ instructions: [Instruction]?, _ funcInstructions: [String:Instruction]?, configuration: Configuration?, strict: Bool? = nil, index: UInt = 0) -> Bool?{
        if let strict = strict{
            self.strict = strict
        }
        
        if let configuration = configuration{
            self.configuration = configuration
        }
        
        if let funcInstructions = funcInstructions {
            self.funcInstructions = funcInstructions
        }
        
        self.runed = true
        self.stepNumber = index
        
        if self.configuration!.global == nil {
            let error = x86Error(details: "The global operand not found", line: 0, column: 0, endError: nil, lineText: "")
            ConsoleLine.error(error: error)
            ConsoleLine.error("Asm Intel x86", "Stopping...")
            self.runed = false
            return false
        }else if self.configuration!.section == nil {
            let error = x86Error(details: "The section operand not found", line: 0, column: 0, endError: nil, lineText: "")
            ConsoleLine.error(error: error)
            ConsoleLine.error("Asm Intel x86", "Stopping...")
            self.runed = false
            return false
        }else if self.funcInstructions[self.configuration!.global!] == nil {
            let error = MainFunctionNotFound(funcName: self.configuration!.global!)
            ConsoleLine.error(error: error)
            ConsoleLine.error("Asm Intel x86", "Stopping...")
            self.runed = false
            return false
        }
        
        if instructions == nil && self.instructions.isEmpty{
            self.runed = false
            return false
        }else if let instructions = instructions{
            let instructionCount = self.instructionsCount(instructions)
            self.maximumStep = instructionCount.0
            self.funcInstructionCount = instructionCount.1
            self.instructions = instructions
            
            if index >= self.maximumStep{
                self.runed = false
                return false
            }
        }
        
        self.executeInstructions = 0
        self.executeFuncInstructions = 0
        self.skipedInstruction = 0
        
        for instruction in instructions ?? self.instructions {
            
            if ((instructions ?? self.instructions).firstIndex(where: { $0.id == instruction.id }))! - Int(self.skipedInstruction) + Int(self.executeFuncInstructions) <= index{
                var result_execute: Bool? = false
                
                if instruction.function && instruction.functionName == self.configuration?.global ?? ""{
                    result_execute = self.executeFunctionStepByStep(funcInstructions ?? self.funcInstructions, functionName: self.configuration?.global ?? "", index: index)
                }else if instruction.function {
                    self.skipedInstruction += 1
                    continue
                }else{
                    self.executeInstructions += 1
                    
                    self.currentInstruction = instruction
                    
                    result_execute = self.executeInstruction(instruction, funcInstructions ?? self.funcInstructions, index: index)
                }
                
                if result_execute == nil{
                    self.runed = false
                    return nil
                }else if result_execute == false{
                    ConsoleLine.error("Asm Intel x86", "Stopping...")
                    self.runed = false
                    return false
                }
            }else{
                return true
            }
        }
                                
        if index >= self.maximumStep{
            ConsoleLine.info("Asm Intel x86", "Stopping...")
            self.runed = false
            return nil
        }else{
            return true
        }
    }
    
    ///
    ///Execute function instructions
    ///
    private func executeFunction(_ funcInstructions: [String:Instruction], functionName: String) -> Bool? {
        let instruction = funcInstructions[functionName]
        
        if let instruction = instruction{
            
            for instruct in instruction.instructions ?? []{
                if instruct.opcode == .ret{
                    print("Stop current function and continue the last function")
                }
                
                let result_execute = self.executeInstruction(instruct, funcInstructions)
                
                if result_execute == nil || result_execute == false{
                    return result_execute
                }
            }
            
            return true
        }else{
            ConsoleLine.error("Asm Intel x86", "Function \(functionName) is not found")
            return nil
        }
    }
    
    ///
    ///Execute function instructions step by step
    ///
    private func executeFunctionStepByStep(_ funcInstructions: [String:Instruction], functionName: String, index: UInt = 0) -> Bool? {
        let instruction = funcInstructions[functionName]
        
        if let instruction = instruction{
            var localInstructionsExecuted = 0
            
            for instruct in instruction.instructions ?? [] {
                
                if instruction.instructions!.firstIndex(where: { $0.id == instruct.id })! + Int(self.executeInstructions) + Int(self.executeFuncInstructions) - localInstructionsExecuted <= index{
                    self.executeFuncInstructions += 1
                    localInstructionsExecuted += 1
                    
                    self.currentInstruction = instruct
                    
                    let result_execute = self.executeInstruction(instruct, funcInstructions, index: index)
                    
                    if result_execute == nil{
                        self.runed = false
                        return nil
                    }else if result_execute == false{
                        ConsoleLine.error("Asm Intel x86", "Stopping...")
                        self.runed = false
                        return false
                    }
                }else{
                    return true
                }
            }
        }else{
            ConsoleLine.error("Asm Intel x86", "Function \(functionName) is not found")
            return nil
        }
        
        return true
    }
    
    private func instructionsCount(_ instructions: [Instruction]) -> (UInt, UInt){
        var instructionCount: UInt = 0
        var funcInstructionCount: UInt = 0
        
        for instruction in instructions {
            switch instruction.opcode {
            case .funcLabel:
                if let funcInstructions = instruction.instructions, !(instruction.instructions?.isEmpty ?? true){
                    let funcInstructCount = self.instructionsCount(funcInstructions)
                    instructionCount += funcInstructCount.0
                    funcInstructionCount += funcInstructCount.0
                }
                
            default:
                instructionCount += 1
            }
        }
        
        return (instructionCount, funcInstructionCount)
    }
    
    private func executeInstruction(_ instruction: Instruction, _ funcInstruction: [String:Instruction], index: UInt? = nil) -> Bool?{
        switch instruction.opcode {
//                Transfer
        case .mov:
            return executeMov(instruction)
        case .xchg:
            return executeXchg(instruction)
            
//                Arithmetic
        case .add:
            return executeAddSub(instruction)
        case .sub:
            return executeAddSub(instruction, add: false)
        case .div:
            return executeMulDiv(instruction, mul: false)
        case .mul:
            return executeMulDiv(instruction)
        case .inc:
            return executeIncDec(instruction)
        case .dec:
            return executeIncDec(instruction, inc: false)
            
//                Logic
        case .neg:
            return executeNeg(instruction)
        case .not:
            return executeNot(instruction)
        case .and:
            return executeAndOrXor(instruction)
        case .or:
            return executeAndOrXor(instruction, action: .or)
        case .xor:
            return executeAndOrXor(instruction, action: .xor)
        case .shl:
            return executeShlShr(instruction)
        case .shr:
            return executeShlShr(instruction, right: true)
            
//            Misc
        case .nop:
//            NOP operator is an equivalent of pass in Python
            return true
        case .lea:
            ConsoleLine.warning("Asm Intel x86", "LEA instruction is not implemented for the moment")
            return true
        case .int:
            let error = NotSupported(instruction: "INT", line: instruction.lineNumber.toUInt(), column: 0, endError: instruction.lineValue.count.toUInt(), lineText: instruction.lineValue)
            ConsoleLine.error(error: error)
            return false
            
//            Jumps
        case .call:
            ConsoleLine.warning("Asm Intel x86", "The CALL instruction does not behave as a real CALL instruction; at the moment, it functions the same as the JMP instruction")
            return self.executeJmp(instruction, funcInstruction, index: index)
        case .ret:
            let error = NotSupported(instruction: "RET", line: instruction.lineNumber.toUInt(), column: 0, endError: instruction.lineValue.count.toUInt(), lineText: instruction.lineValue)
            ConsoleLine.error(error: error)
            return false
        case .jmp:
            return self.executeJmp(instruction, funcInstruction, index: index)
        
//                Stop
        case .hlt:
            ConsoleLine.info("Asm Intel x86", "Stopping...")
            return nil
            
//            Function
        case .funcLabel:
            return true
            
//            Custom element
        case .PRINT:
            return self.executePRINT(instruction)
        }
    }
    
    
//    Execute opCode
    private func executeMov(_ instruction: Instruction) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 2 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        let operand2 = instruction.operands[1]
        
        switch operand1{
        case .register(let registerType):
            let _ = verifyRegisterExist(registerType, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerType })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                return false
            }
        case .memory(_):
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        default:
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Operand not supported", color: .red)
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value{
                    if let newRegisterValue = Register.getRegisterValue(registerDest.type, convertRegisterValue(registerValue.value)){
                        let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                        self.registers.updateValue(newRegister, forKey: registerDest.type)
                    }else{
                        return false
                    }
                }else{
//                    Error
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                if let registerValue = Register.getRegisterValue(registerDest.type, value){
                    let register = Register(type: registerDest.type, size: registerDest.size, value: registerValue)
                    
                    self.registers.updateValue(register, forKey: registerDest.type)
                }else{
                    return false
                }
                
            case .memory(_):
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
                return false
            case .functions(_):
                ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
                return false
            }
            
            return true
        }        
    }
    
    private func executeAddSub(_ instruction: Instruction, add: Bool = true) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 2 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        let operand2 = instruction.operands[1]
        
        switch operand1 {
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        case .functions(_):
            ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
                
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value {
                    let resultAdd = add ? self.convertRegisterValue(registerDest.value) &+ self.convertRegisterValue(registerValue.value) : 0
                    let resultSub = add ? 0 : self.convertRegisterValue(registerDest.value) &- self.convertRegisterValue(registerValue.value)
                    
                    if let newRegisterValue = Register.getRegisterValue(registerDest.type, add ? resultAdd : resultSub){
                        let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                        self.registers.updateValue(newRegister, forKey: registerDest.type)
                    }else{
                        return false
                    }
                    
                }else{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                let resultAdd = self.convertRegisterValue(registerDest.value) &+ value
                let resultSub = self.convertRegisterValue(registerDest.value) &- value
                
                if let newRegisterValue = Register.getRegisterValue(registerDest.type, add ? resultAdd : resultSub){
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                }else{
                    return false
                }
                
            case .memory(_):
                ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
                return false
            case .functions(_):
                ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
                return false
            }
            
            return true
        }
    }
    
    
    private func executeMulDiv(_ instruction: Instruction, mul: Bool = true) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 2 arguments", color: .red)
            return false
        }
        
        ConsoleLine.shared.appendLine("Asm Intel x86 (WARNING)", "Instruction \(instruction.opcode.rawValue.uppercased()) does not represent the true functioning", color: .orange)
        
        let operand1 = instruction.operands[0]
        let operand2 = instruction.operands[1]
        
        switch operand1 {
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        case .functions(_):
            ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
                
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value {
                    let resultMul = self.convertRegisterValue(registerDest.value) &* self.convertRegisterValue(registerValue.value)
                    let resultDiv = self.convertRegisterValue(registerDest.value) / self.convertRegisterValue(registerValue.value)
                    
                    if let newRegisterValue = Register.getRegisterValue(registerDest.type, mul ? resultMul : resultDiv){
                        let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                        self.registers.updateValue(newRegister, forKey: registerDest.type)
                    }else{
                        return false
                    }
                    
                }else{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                let resultMul = mul ? self.convertRegisterValue(registerDest.value) &* value : 0
                let resultDiv = mul ? 0 : (value == 0 ? nil : self.convertRegisterValue(registerDest.value) / value)
                
                if resultDiv == nil{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Division by 0 is not allowed", color: .red)
                    return false
                }
                
                if let newRegisterValue = Register.getRegisterValue(registerDest.type, mul ? resultMul : resultDiv!){
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                }else{
                    return false
                }
                
            case .memory(_):
                ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
                return false
            case .functions(_):
                ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
                return false
            }
            
            return true
        }
    }
    
    
    private func executeIncDec(_ instruction: Instruction, inc: Bool = true) -> Bool {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 1 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        
        switch operand1 {
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        case .functions(_):
            ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            let resultInc = self.convertRegisterValue(registerDest.value) &+ 1
            let resultDec = self.convertRegisterValue(registerDest.value) &- 1
            
            if let newRegisterValue = Register.getRegisterValue(registerDest.type, inc ? resultInc : resultDec){
                let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                self.registers.updateValue(newRegister, forKey: registerDest.type)
            }else{
                return false
            }
            
            return true
        }
    }
    
    
    private func executeNot(_ instruction: Instruction) -> Bool {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 1 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        
        switch operand1 {
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        case .functions(_):
            ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            var result = 0
            
            switch registerDest.value {
            case .int16(let int16):
                if int16 < 0{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "NOT operator does not accept negative value", color: .red)
                    return false
                }
                result = Int(~UInt16(int16) & ~(1 << 15))
            case .int32(let int32):
                if int32 < 0{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "NOT operator does not accept negative value", color: .red)
                    return false
                }
                result = Int(~UInt32(int32) & ~(1 << 31))
            case .int64(let int64):
                if int64 < 0{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "NOT operator does not accept negative value", color: .red)
                    return false
                }
                result = Int(~UInt64(int64) & ~(1 << 63))
            }
                        
            if let newRegisterValue = Register.getRegisterValue(registerDest.type, result){
                let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                self.registers.updateValue(newRegister, forKey: registerDest.type)
            }else{
                return false
            }
            
            return true
        }
    }
    
    
    private func executeNeg(_ instruction: Instruction) -> Bool {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 1 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        
        switch operand1 {
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        case .functions(_):
            ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            var result = 0
            
            switch registerDest.value {
            case .int16(let int16):
                result = Int(0-int16)
            case .int32(let int32):
                result = Int(0-int32)
            case .int64(let int64):
                result = Int(0-int64)
            }
            
            if let newRegisterValue = Register.getRegisterValue(registerDest.type, result){
                let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                self.registers.updateValue(newRegister, forKey: registerDest.type)
            }else{
                return false
            }
            
            return true
        }
    }
    
    
    private func executeAndOrXor(_ instruction: Instruction, action: AndOrXor = .and) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 2 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        let operand2 = instruction.operands[1]
        
        switch operand1 {
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        case .functions(_):
            ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
                
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value {
                    let resultAnd = self.convertRegisterValue(registerDest.value) & self.convertRegisterValue(registerValue.value)
                    let resultOr = self.convertRegisterValue(registerDest.value) | self.convertRegisterValue(registerValue.value)
                    let resultXor = self.convertRegisterValue(registerDest.value) ^ self.convertRegisterValue(registerValue.value)
                    
                    if let newRegisterValue = Register.getRegisterValue(registerDest.type, action.getValue(resultAnd, resultOr, resultXor)){
                        let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                        self.registers.updateValue(newRegister, forKey: registerDest.type)
                    }else{
                        return false
                    }
                    
                }else{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                let resultAnd = self.convertRegisterValue(registerDest.value) & value
                let resultOr = self.convertRegisterValue(registerDest.value) | value
                let resultXor = self.convertRegisterValue(registerDest.value) ^ value
                
                if let newRegisterValue = Register.getRegisterValue(registerDest.type, action.getValue(resultAnd, resultOr, resultXor)){
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                }else{
                    return false
                }
                
            case .memory(_):
                ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
                return false
            case .functions(_):
                ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
                return false
            }
            
            return true
        }
    }
    
    private enum AndOrXor{
        case and
        case or
        case xor
        
        func getValue(_ andValue: Int, _ orValue: Int, _ xorValue: Int) -> Int{
            switch self {
            case .and:
                return andValue
            case .or:
                return orValue
            case .xor:
                return xorValue
            }
        }
    }
    
    private func executeShlShr(_ instruction: Instruction, right: Bool = false) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 2 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        let operand2 = instruction.operands[1]
        
        switch operand1 {
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        case .functions(_):
            ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
                
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value {
                    let resultLeft = self.convertRegisterValue(registerDest.value) << self.convertRegisterValue(registerValue.value)
                    let resultRight = self.convertRegisterValue(registerDest.value) >> self.convertRegisterValue(registerValue.value)
                    
                    if let newRegisterValue = Register.getRegisterValue(registerDest.type, right ? resultRight : resultLeft){
                        let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                        self.registers.updateValue(newRegister, forKey: registerDest.type)
                    }else{
                        return false
                    }
                    
                }else{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                let resultLeft = self.convertRegisterValue(registerDest.value) << value
                let resultRight = self.convertRegisterValue(registerDest.value) >> value
                
                if let newRegisterValue = Register.getRegisterValue(registerDest.type, right ? resultRight : resultLeft){
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                }else{
                    return false
                }
                
            case .memory(_):
                ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
                return false
            case .functions(_):
                ConsoleLine.shared.error("Asm Intel x86", "An error occured to interpret the code")
                return false
            }
            
            return true
        }
    }
    
    
    private func executeJmp(_ instruction: Instruction, _ funcInstruction: [String:Instruction], index: UInt?) -> Bool? {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 1 arguments", color: .red)
            return false
        }
        
        let operand = instruction.operands[0]
        
        switch operand{
        case .functions(let funcName):
            if let index = index{
                let result = self.executeFunctionStepByStep(funcInstruction, functionName: funcName, index: index)
                
                return result
            }else{
                let result = self.executeFunction(funcInstruction, functionName: funcName)
                
                return result
            }
        default:
            ConsoleLine.shared.error("Asm Intel x86", "Instruction JMP only accept function name for argument")
            return false
        }
    }
    
    
    private func executeXchg(_ instruction: Instruction) -> Bool?{
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 2 arguments", color: .red)
            return false
        }
        
        let operand1 = instruction.operands[0]
        let operand2 = instruction.operands[1]
        
        switch operand1{
        case .register(let registerTypeDest):
            let _ = verifyRegisterExist(registerTypeDest, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == registerTypeDest })?.value {
                return executeRegister(register)
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
            
        default:
            ConsoleLine.error("Asm Intel x86", "Instruction XCHG only accept register")
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
                
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerSrc =  self.registers.first(where: { $0.key == registerType })?.value {
                    
                    if let newRegisterDestValue = Register.getRegisterValue(registerDest.type, registerSrc.value.value()), let newRegisterSrcValue = Register.getRegisterValue(registerSrc.type, registerDest.value.value()){
                                                
                        let newRegisterDest = Register(type: registerDest.type, size: registerDest.size, value: newRegisterDestValue)
                        let newRegisterSrc = Register(type: registerSrc.type, size: registerSrc.size, value: newRegisterSrcValue)
                        
                        self.registers.updateValue(newRegisterDest, forKey: registerDest.type)
                        self.registers.updateValue(newRegisterSrc, forKey: registerSrc.type)
                    }else{
                        return false
                    }
                    
                }else{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            default:
                ConsoleLine.error("Asm Intel x86", "Instruction XCHG only accept register")
                return false
            }
            
            return true
        }
    }
    
    
    private func executePRINT(_ instruction: Instruction) -> Bool? {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode.rawValue.uppercased()) require 1 arguments", color: .red)
            return false
        }
        
        let operand = instruction.operands[0]
        
        switch operand {
        case .register(let register):
            let _ = verifyRegisterExist(register, strict: self.strict)
            
            if let register = self.registers.first(where: { $0.key == register })?.value {
                ConsoleLine.debug("USER", String(register.value.value()))
                return true
            }else{
//                Error
                ConsoleLine.shared.appendLine("Asm Intel x86", "Register \(register.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(let imediate):
            ConsoleLine.debug("USER", String(imediate))
            return true
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
            return false
        default:
            ConsoleLine.error("Asm Intel x86", "Instruction XCHG only accept register")
            return false
        }
    }
    
    
//    Interpreter function
    
    private func verifyRegisterExist(_ register: X86Register, strict: Bool = false) -> Bool {
        if !self.registers.keys.contains(register){
            if strict{
                return false
            }
            
            let registerInfo = Register.getRegisterInfo(register)
            let defaultValue = Register(type: register, size: registerInfo.size, value: registerInfo.value)
            self.registers.updateValue(defaultValue, forKey: register)
        }
        
        return true
    }
    
    private func convertRegisterValue(_ value: RegisterValue) -> Int {
        switch value {
        case .int16(let int16):
            return Int(int16)
        case .int32(let int32):
            return Int(int32)
        case .int64(let int64):
            return Int(int64)
        }
    }
}
