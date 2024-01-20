//
//  Interpreter.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import Foundation


class Asm80186Interpreter: ObservableObject {
    @Published var registers = [X86Register:Register]()
    @Published var stepNumber: UInt = 0
    @Published var maximumStep: Int = 0
    @Published var runed = false
    @Published var currentInstruction: Instruction?
    
    var strict: Bool = false
    var instructions = [Instruction]()
    
    func interpret(_ instructions: [Instruction], strict: Bool = false) {
        self.strict = strict
        self.runed = true
        
        for instruction in instructions {
            let result_execute = self.executeInstruction(instruction)
            
            if result_execute == nil{
                return
            }else if result_execute == false{
                ConsoleLine.shared.appendLine("Asm Intel x86", "Stopping...", color: .red)
                return
            }
        }
        
        ConsoleLine.shared.appendLine("Asm Intel x86", "Stopping...", color: .green)
        self.runed = false
    }
    
    ///
    ///Run interpreter step by step
    ///
    func interpretStepByStep(_ instructions: [Instruction]?, strict: Bool? = nil, index: UInt = 0) -> Bool?{
        if let strict = strict{
            self.strict = strict
        }
        
        self.runed = true
        self.stepNumber = index
        
        if instructions == nil && self.instructions.isEmpty{
            self.runed = false
            return false
        }else if let instructions = instructions{
            self.maximumStep = instructions.count - 1
            self.instructions = instructions
            
            if index >= self.maximumStep{
                return false
            }
        }
                
        for instruction in instructions ?? self.instructions {
            if ((instructions ?? self.instructions).firstIndex(where: { $0.id == instruction.id }))! <= index{
                let result_execute = self.executeInstruction(instruction)
                
                self.currentInstruction = instruction
                
                if result_execute == nil{
                    return nil
                }else if result_execute == false{
                    ConsoleLine.shared.appendLine("Asm Intel x86", "Stopping...", color: .red)
                    return false
                }
            }else{
                return true
            }
        }
        
        if index > self.maximumStep{
            ConsoleLine.shared.appendLine("Asm Intel x86", "Stopping...", color: .green)
            return nil
        }else{
            return true
        }
    }
    
    private func executeInstruction(_ instruction: Instruction) -> Bool?{
        switch instruction.opcode {
//                Transfer
        case .mov:
            return executeMov(instruction)
            
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
            return true
        case .or:
            return true
        case .xor:
            return true
        
//                Stop
        case .hlt:
            ConsoleLine.shared.appendLine("Asm Intel x86", "Stopping...", color: .green)
            return nil
        }
    }
    
    
//    Execute opCode
    private func executeMov(_ instruction: Instruction) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode) require 2 arguments", color: .red)
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
            }
            
            return true
        }        
    }
    
    private func executeAddSub(_ instruction: Instruction, add: Bool = true) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode) require 2 arguments", color: .red)
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
                    let resultAdd = add ? self.convertRegisterValue(registerDest.value) + self.convertRegisterValue(registerValue.value) : 0
                    let resultSub = add ? 0 : self.convertRegisterValue(registerDest.value) - self.convertRegisterValue(registerValue.value)
                    
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
                let resultAdd = self.convertRegisterValue(registerDest.value) + value
                let resultSub = self.convertRegisterValue(registerDest.value) - value
                
                if let newRegisterValue = Register.getRegisterValue(registerDest.type, add ? resultAdd : resultSub){
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                }else{
                    return false
                }
                
            case .memory(_):
                ConsoleLine.shared.appendLine("Asm Intel x86", "Memory is not supported", color: .red)
                return false
            }
            
            return true
        }
    }
    
    
    private func executeMulDiv(_ instruction: Instruction, mul: Bool = true) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode) require 2 arguments", color: .red)
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
                    let resultMul = self.convertRegisterValue(registerDest.value) * self.convertRegisterValue(registerValue.value)
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
                let resultMul = mul ? self.convertRegisterValue(registerDest.value) * value : 0
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
            }
            
            return true
        }
    }
    
    
    private func executeIncDec(_ instruction: Instruction, inc: Bool = true) -> Bool {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode) require 1 arguments", color: .red)
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
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            let resultInc = self.convertRegisterValue(registerDest.value) + 1
            let resultDec = self.convertRegisterValue(registerDest.value) - 1
            
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
        ConsoleLine.shared.appendLine("Asm Intel x86", "WARNING: NOT is not functionnal for the moment", color: .orange)
        
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode) require 1 arguments", color: .red)
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
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            var result = 0
            
            switch registerDest.value {
            case .int16(let int16):
                result = Int(~int16)
            case .int32(let int32):
                result = Int(~int32)
            case .int64(let int64):
                result = Int(~int64)
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
            ConsoleLine.shared.appendLine("Asm Intel x86", "Instruction \(instruction.opcode) require 1 arguments", color: .red)
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
