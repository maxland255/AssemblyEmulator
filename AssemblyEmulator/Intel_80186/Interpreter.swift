//
//  Interpreter.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import Foundation


class Asm80186Interpreter: ObservableObject {
    @Published var registers = [X86Register:Register]()
    var strict: Bool = false
    
    func interpret(_ instructions: [Instruction], strict: Bool = false) {
        self.strict = strict
        
        for instruction in instructions {
            switch instruction.opcode {
//                Transfer
            case .mov:
                if !executeMov(instruction){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
                
//                Arithmetic
            case .add:
                if !executeAddSub(instruction){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
            case .sub:
                if !executeAddSub(instruction, add: false){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
            case .div:
                if !executeMulDiv(instruction, mul: false){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
            case .mul:
                if !executeMulDiv(instruction){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
            case .inc:
                if !executeIncDec(instruction){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
            case .dec:
                if !executeIncDec(instruction, inc: false){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
                
//                Logic
            case .neg:
                if !executeNeg(instruction){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
            case .not:
                if !executeNot(instruction){
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .red)
                    return
                }
            case .and:
                continue
            case .or:
                continue
            case .xor:
                continue
            
//                Stop
            case .hlt:
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .green)
                return
            }
        }
        
        ConsoleLine.shared.appendLine("Asm 80186 x86", "Stopping...", color: .green)
    }
    
    
//    Execute opCode
    private func executeMov(_ instruction: Instruction) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Instruction \(instruction.opcode) require 2 arguments", color: .red)
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
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerType.rawValue) does not exist", color: .red)
                return false
            }
        case .memory(_):
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
            return false
        default:
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Operand not supported", color: .red)
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value{
                    let newRegisterValue = Register.getRegisterValue(registerDest.type, convertRegisterValue(registerValue.value))
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                }else{
//                    Error
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                let registerValue = Register.getRegisterValue(registerDest.type, value)
                
                let register = Register(type: registerDest.type, size: registerDest.size, value: registerValue)
                
                self.registers.updateValue(register, forKey: registerDest.type)
                
            case .memory(_):
//                Error
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
                return false
            }
            
            return true
        }        
    }
    
    private func executeAddSub(_ instruction: Instruction, add: Bool = true) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Instruction \(instruction.opcode) require 2 arguments", color: .red)
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
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
                
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value {
                    let resultAdd = self.convertRegisterValue(registerDest.value) + self.convertRegisterValue(registerValue.value)
                    let resultSub = self.convertRegisterValue(registerDest.value) - self.convertRegisterValue(registerValue.value)
                    
                    let newRegisterValue = Register.getRegisterValue(registerDest.type, add ? resultAdd : resultSub)
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                    
                }else{
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                let resultAdd = self.convertRegisterValue(registerDest.value) + value
                let resultSub = self.convertRegisterValue(registerDest.value) - value
                
                let newRegisterValue = Register.getRegisterValue(registerDest.type, add ? resultAdd : resultSub)
                let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                self.registers.updateValue(newRegister, forKey: registerDest.type)
                
            case .memory(_):
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
                return false
            }
            
            return true
        }
    }
    
    
    private func executeMulDiv(_ instruction: Instruction, mul: Bool = true) -> Bool {
        guard instruction.operands.count == 2 else {
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Instruction \(instruction.opcode) require 2 arguments", color: .red)
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
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            switch operand2 {
                
            case .register(let registerType):
                let result = verifyRegisterExist(registerType, strict: self.strict)
                
                if !result{
    //                Error
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
                if let registerValue =  self.registers.first(where: { $0.key == registerType })?.value {
                    let resultMul = self.convertRegisterValue(registerDest.value) * self.convertRegisterValue(registerValue.value)
                    let resultDiv = self.convertRegisterValue(registerDest.value) / self.convertRegisterValue(registerValue.value)
                    
                    let newRegisterValue = Register.getRegisterValue(registerDest.type, mul ? resultMul : resultDiv)
                    let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                    self.registers.updateValue(newRegister, forKey: registerDest.type)
                    
                }else{
                    ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerType.rawValue) does not exist", color: .red)
                    return false
                }
                
            case .immediate(let value):
                let resultMul = self.convertRegisterValue(registerDest.value) * value
                let resultDiv = self.convertRegisterValue(registerDest.value) / value
                
                let newRegisterValue = Register.getRegisterValue(registerDest.type, mul ? resultMul : resultDiv)
                let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
                self.registers.updateValue(newRegister, forKey: registerDest.type)
                
            case .memory(_):
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
                return false
            }
            
            return true
        }
    }
    
    
    private func executeIncDec(_ instruction: Instruction, inc: Bool = true) -> Bool {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Instruction \(instruction.opcode) require 1 arguments", color: .red)
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
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
            return false
        }
        
        func executeRegister(_ registerDest: Register) -> Bool {
            let resultInc = self.convertRegisterValue(registerDest.value) + 1
            let resultDec = self.convertRegisterValue(registerDest.value) - 1
            
            let newRegisterValue = Register.getRegisterValue(registerDest.type, inc ? resultInc : resultDec)
            let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
            self.registers.updateValue(newRegister, forKey: registerDest.type)
            
            return true
        }
    }
    
    
    private func executeNot(_ instruction: Instruction) -> Bool {
        ConsoleLine.shared.appendLine("Asm 80186 x86", "WARNING: NOT is not functionnal for the moment", color: .orange)
        
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Instruction \(instruction.opcode) require 1 arguments", color: .red)
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
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
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
            
            let newRegisterValue = Register.getRegisterValue(registerDest.type, result)
            let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
            self.registers.updateValue(newRegister, forKey: registerDest.type)
            
            return true
        }
    }
    
    
    private func executeNeg(_ instruction: Instruction) -> Bool {
        guard instruction.operands.count == 1 else {
//            Error
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Instruction \(instruction.opcode) require 1 arguments", color: .red)
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
                ConsoleLine.shared.appendLine("Asm 80186 x86", "Register \(registerTypeDest.rawValue) does not exist", color: .red)
                return false
            }
        case .immediate(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "The first argument only accept register", color: .red)
            return false
        case .memory(_):
            ConsoleLine.shared.appendLine("Asm 80186 x86", "Memory is not supported", color: .red)
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
            
            let newRegisterValue = Register.getRegisterValue(registerDest.type, result)
            let newRegister = Register(type: registerDest.type, size: registerDest.size, value: newRegisterValue)
            self.registers.updateValue(newRegister, forKey: registerDest.type)
            
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
