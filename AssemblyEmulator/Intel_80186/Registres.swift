//
//  Registres.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import Foundation
import SwiftUI


struct Register: Hashable, Identifiable {
    let id = UUID().uuidString
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
    
    static func getRegisterValue(_ register: X86Register, _ value: Int) -> RegisterValue? {
        switch register {
        // 16-bit registers
        case .ax, .bx, .cx, .dx, .si, .di, .bp, .sp,
                .cs, .ds, .ss, .es, .fs, .gs,
                .siIndex, .diIndex, .ip, .flags, .cr0:
            if value <= Int16.max && value >= Int16.min{
                return .int16(Int16(value))
            }else{
                ConsoleLine.error("Asm Intel x86", "\(value <= Int16.max ? "Underflow" : "Overflow") for \(register.rawValue) detected (value: \(String(value, radix: 16))), max value allowed: \(String(Int16.max, radix: 16)) and min valued allowed: \(String(Int16.min, radix: 16))")
                return nil
            }
                
        // 32-bit registers
        case .eax, .ebx, .ecx, .edx, .esi, .edi, .ebp, .esp,
                .esiIndex32, .ediIndex32, .eip, .eflags:
            if value <= Int32.max && value >= Int32.min{
                return .int32(Int32(value))
            }else{
                ConsoleLine.error("Asm Intel x86", "\(value <= Int32.max ? "Underflow" : "Overflow") for \(register.rawValue) detected (value: \(String(value, radix: 16))), max value allowed: \(String(Int32.max, radix: 16)) and min valued allowed: \(String(Int32.min, radix: 16))")
                return nil
            }
            
        // 64-bit registers
        case .rax, .rbx, .rcx, .rdx, .rsi, .rdi, .rbp, .rsp,
                .rsiIndex64, .rdiIndex64, .rip, .rflags:
            if value <= Int64.max && value >= Int64.min{
                return .int64(Int64(value))
            }else{
                ConsoleLine.error("Asm Intel x86", "\(value <= Int64.max ? "Underflow" : "Overflow") for \(register.rawValue) detected (value: \(String(value, radix: 16))), max value allowed: \(String(Int64.max, radix: 16)) and min valued allowed: \(String(Int64.min, radix: 16))")
                return nil
            }
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

enum X86Register: String, Hashable, CaseIterable {
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


extension X86Register{
    static func values() -> [String]{
        return self.allCases.map { $0.rawValue }
    }
}


struct RegisterView: View {
    
    var registers: [Register]
    
    @State var viewWidth: CGFloat = 200
    @State var selectedRegister: Register?
    
    var body: some View {
        HStack(spacing: 0) {
            Divider()
                .frame(width: 2)
                .onHover(perform: { hovered in
                    if hovered{
                        NSCursor.resizeLeftRight.push()
                    }else{
                        NSCursor.resizeLeftRight.pop()
                    }
                })
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged({ value in
                            let width = CGFloat(integerLiteral: Int(value.translation.width))
                                                        
                            if viewWidth - width >= 200 && viewWidth - width <= 400{
                                viewWidth -= width
                            }
                        })
                )
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Registers")
                        .font(.title)
                    
                    Spacer()
                }.padding(.top, 7.5)
                
                ScrollView {
                    ForEach(registers.sorted(by: { $0.type.rawValue < $1.type.rawValue }), id: \.type) { register in
                        HStack {
                            Text("\(register.type.rawValue.uppercased()) (\(register.size.rawValue) bits): \(String(register.value.value(), radix: 16, uppercase: true)) (\(register.value.value()))")
                                .padding(.bottom, 2.5)
                                .onTapGesture {
                                    self.selectedRegister = register
                                }
                                .onHover { hovered in
                                    if hovered{
                                        NSCursor.pointingHand.push()
                                    }else{
                                        NSCursor.pointingHand.pop()
                                    }
                                }
                            
                            Spacer()
                        }
                    }
                }.sheet(item: $selectedRegister) { register in
                    RegisterDetails(register: register)
                }
            }.padding(.leading)
        }.frame(width: viewWidth)
    }
}


struct RegisterDetails: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var register: Register
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(register.type.rawValue.uppercased())
                    .font(.title2)
                
                Text("Register size: \(register.size.rawValue) bits")
                
                Text("Binary value: \(String(register.value.value(), radix: 2))")
                    .textSelection(.enabled)
                
                Text("Hexadecimal value: \(String(register.value.value(), radix: 16).uppercased())")
                    .textSelection(.enabled)
                
                Text("Decimal value: \(register.value.value())")
                    .textSelection(.enabled)
            }.padding()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}
