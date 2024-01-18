//
//  Intel_x86_80186_UI.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import SwiftUI

struct Intel_x86_80186_UI: View {
    
    @ObservedObject var interpreter = Asm80186Interpreter()
    
    @State var parser = Asm80186Parser()
    
    @State var processor: ProcessorType = .none
    
    @State var sourceCode = ""
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                TextEditor(text: $sourceCode)
                    .font(Font.system(size: 14))
                
                ConsoleView()
                    .frame(height: 200)
            }
            
            RegisterView(registers: Array(interpreter.registers.values))
                .background(VisualEffect())
                .frame(width: 200)
        }.toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Button(action: {
    //                    Reset all register
                        switch processor {
                        case .none:
                            interpreter.registers = [:]
                        case .intel_80186, .intel_80286:
                            interpreter.registers = processor.getProcessorRegister()
                        }
                        
                        let instructions = parser.parse(sourceCode)
                                                                
                        interpreter.interpret(instructions, strict: processor != .none)
                    }, label: {
                        Image(systemName: "play")
                    }).disabled(sourceCode.isEmpty)
                                        
                    Menu(processor.rawValue) {
                        ForEach(ProcessorType.allCases, id: \.self) { type in
                            Button {
                                processor = type
                                
                                switch type {
                                case .none:
                                    interpreter.registers = [:]
                                case .intel_80186, .intel_80286:
                                    interpreter.registers = processor.getProcessorRegister()
                                }
                            } label: {
                                Text(type.rawValue)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    Intel_x86_80186_UI()
}


enum ProcessorType: String, CaseIterable {
    case none = "No processor selected"
    case intel_80186 = "Intel 80186"
    case intel_80286 = "Intel 80286"
}


extension ProcessorType {
    func getProcessorRegister() -> [X86Register:Register]{
        switch self {
        case .none:
            return [:]
        case .intel_80186:
            let x86Register: [X86Register] = [.ax, .bx, .cx, .dx, .si, .di, .cs, .ds, .ss, .es, .ip, .sp, .flags]
            
            var registers = [X86Register:Register]()
            
            for x86Register in x86Register {
                let register = self.initRegister(x86Register)
                registers.updateValue(register, forKey: x86Register)
            }
            
            return registers
        case .intel_80286:
            let x86Register: [X86Register] = [.ax, .bx, .cs, .dx, .si, .di, .cs, .ds, .ss, .es, .ip, .sp, .flags, .cr0, .eax, .ebx, .ecx, .edx, .esi, .edi, .esp, .ebp, .eip, .eflags]
            
            var registers = [X86Register:Register]()
            
            for x86Register in x86Register {
                let register = self.initRegister(x86Register)
                registers.updateValue(register, forKey: x86Register)
            }
            
            return registers
        }
    }
    
    private func initRegister(_ x86Register: X86Register) -> Register{
        let info = Register.getRegisterInfo(x86Register)
        
        let register = Register(type: x86Register, size: info.size, value: info.value)
        
        return register
    }
}
