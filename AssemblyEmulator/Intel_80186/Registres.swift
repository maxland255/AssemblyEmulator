//
//  Registres.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import Foundation
import SwiftUI


struct Register: Hashable {
    let type: X86Register
    let size: RegisterSize
    var value: RegisterValue
    var isGeneralPurpose: Bool
    
    init(type: X86Register, size: RegisterSize, value: RegisterValue, isGeneralPurpose: Bool = true) {
        self.type = type
        self.size = size
        self.value = value
        self.isGeneralPurpose = isGeneralPurpose
    }
    
    static func getRegisterInfo(_ register: X86Register) -> (size: RegisterSize, value: RegisterValue) {
        switch register {
        // 16-bit registers
        case .ax, .bx, .cx, .dx, .si, .di, .bp, .sp,
             .cs, .ds, .ss, .es, .fs, .gs,
             .siIndex, .diIndex, .ip, .flags, .cr0:
            return (._16, .int16(0)) // The default value is 0
            
        // 32-bit registers
        case .eax, .ebx, .ecx, .edx, .esi, .edi, .ebp, .esp,
             .esiIndex32, .ediIndex32, .eip, .eflags:
            return (._32, .int32(0)) // The default value is 0
        
        // 64-bit registers
        case .rax, .rbx, .rcx, .rdx, .rsi, .rdi, .rbp, .rsp,
             .rsiIndex64, .rdiIndex64, .rip, .rflags:
            return (._64, .int64(0)) // The default value is 0
        }
    }
    
    static func getRegisterValue(_ register: X86Register, _ value: Int) -> RegisterValue {
        switch register {
        // 16-bit registers
        case .ax, .bx, .cx, .dx, .si, .di, .bp, .sp,
                .cs, .ds, .ss, .es, .fs, .gs,
                .siIndex, .diIndex, .ip, .flags, .cr0:
        return .int16(Int16(value))
                
        // 32-bit registers
        case .eax, .ebx, .ecx, .edx, .esi, .edi, .ebp, .esp,
                .esiIndex32, .ediIndex32, .eip, .eflags:
        return .int32(Int32(value))
            
        // 64-bit registers
        case .rax, .rbx, .rcx, .rdx, .rsi, .rdi, .rbp, .rsp,
                .rsiIndex64, .rdiIndex64, .rip, .rflags:
        return .int64(Int64(value))
        }
    }
}


enum RegisterSize: String, Hashable {
    case _16 = "16"
    case _32 = "32"
    case _64 = "64"
}

enum RegisterValue: Hashable {
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
}

extension RegisterValue {
    func value() -> Int {
        switch self {
        case .int16(let int16):
            return Int(int16)
        case .int32(let int32):
            return Int(int32)
        case .int64(let int64):
            return Int(int64)
        }
    }
}

enum X86Register: String, Hashable {
    // 16-bit general registers
    case ax, bx, cx, dx, si, di, bp, sp
    
    // 16-bit segment registers
    case cs, ds, ss, es, fs, gs
    
    // 16-bit index registers
    case siIndex = "siIndex", diIndex = "diIndex"
    
    // Special 16-bit registers
    case ip, flags
    
    // 16-bit control registers
    case cr0
    
    // 32-bit general registers
    case eax, ebx, ecx, edx, esi, edi, ebp, esp
    
    // 32-bit index registers
    case esiIndex32 = "esiIndex", ediIndex32 = "ediIndex"
    
    // 32-bit special registers
    case eip, eflags
    
    // 64-bit general registers
    case rax, rbx, rcx, rdx, rsi, rdi, rbp, rsp
    
    // 64-bit index registers
    case rsiIndex64 = "rsiIndex", rdiIndex64 = "rdiIndex"
    
    // 64-bit special registers
    case rip, rflags
}


struct RegisterView: View {
    
    var registers: [Register]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Registers")
                    .font(.title)
                
                Spacer()
            }.padding(.top, 7.5)
            
            ScrollView {
                ForEach(registers.sorted(by: { $0.type.rawValue < $1.type.rawValue }), id: \.type) { register in
                    HStack {
                        Text("\(register.type.rawValue) (\(register.size.rawValue) bits): \(String(register.value.value(), radix: 16, uppercase: true)) (\(register.value.value()))")
                            .padding(.bottom, 2.5)
                        
                        Spacer()
                    }
                }
            }
        }.padding(.leading)
    }
}
