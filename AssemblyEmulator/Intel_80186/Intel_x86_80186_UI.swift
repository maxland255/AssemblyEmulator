//
//  Intel_x86_80186_UI.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import SwiftUI
import CodeEditorView
import LanguageSupport

struct Intel_x86_80186_UI: View {
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    @ObservedObject var interpreter = Asm80186Interpreter()
    
    @State var parser = Asm80186Parser()
    
    @State var processor: ProcessorType = .none
    
    @State var sourceCode = ""
    @SceneStorage("editPosition") private var editPosition: CodeEditor.Position = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = Set ()
    
    @State var runedStepByStep = false
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                if runedStepByStep, let currentInstruction = interpreter.currentInstruction{
                    VStack(spacing: 0) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .foregroundStyle(.background)
                            
                            Text("Current line: \"\(currentInstruction.lineValue)\" (line number: \(currentInstruction.lineNumber))")
                                .padding(.horizontal)
                        }.frame(height: 30)
                        
                        Divider()
                    }
                }
                
                CodeEditor(
                    text: $sourceCode,
                    position: $editPosition,
                    messages: $messages,
                    language: .intel_x86(),
                    layout: CodeEditor.LayoutConfiguration(showMinimap: false, wrapText: false)
                )
                    .environment(\.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
                
//                TextEditor(text: $sourceCode)
//                    .font(Font.system(size: 14))
                
                ConsoleView()
            }
            
            RegisterView(registers: Array(interpreter.registers.values))
                .background(VisualEffect())
        }.toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button(action: {
                        // Reset all register
                        switch processor {
                        case .none:
                            interpreter.registers = [:]
                        case .intel_80186, .intel_80286:
                            interpreter.registers = processor.getProcessorRegister()
                        }
                        
                        let instructions = parser.parse(sourceCode)
                                                                
                        if !instructions.isEmpty{
                            interpreter.interpret(instructions, strict: processor != .none)
                        }
                    }, label: {
                        Image(systemName: "play.fill")
                    }).disabled(sourceCode.isEmpty || runedStepByStep)
                        .keyboardShortcut("r", modifiers: .command)
                        .help("Run (Command + R)")
                    
                    Button {
                        // Reset all register
                        switch processor {
                        case .none:
                            interpreter.registers = [:]
                        case .intel_80186, .intel_80286:
                            interpreter.registers = processor.getProcessorRegister()
                        }
                        
                        let instructions = parser.parse(sourceCode)
                                                                
                        if !instructions.isEmpty{
                            self.runedStepByStep = true
                            let result_interpreter = interpreter.interpretStepByStep(instructions, strict: processor != .none)
                                                        
                            if result_interpreter == false{
                                self.stopInterpreter()
                            }
                        }
                    } label: {
                        Image(systemName: "play.square.stack")
                    }.disabled(sourceCode.isEmpty || runedStepByStep)
                        .keyboardShortcut("e", modifiers: .command)
                        .help("Run step by step (Command + E)")
                    
                    if runedStepByStep{
                        Button {
                            self.stopInterpreter()
                            
                            ConsoleLine.shared.appendLine("Asm Intel x86", "Killed by user", color: .green)
                        } label: {
                            Image(systemName: "square.fill")
                        }
                        
                        Button {
                            let result_interpreter = interpreter.interpretStepByStep(nil, index: interpreter.stepNumber - 1)
                            
                            if result_interpreter == false{
                                self.stopInterpreter()
                            }
                        } label: {
                            Image(systemName: "arrow.turn.up.left")
                        }.disabled(interpreter.stepNumber == 0)
                            .keyboardShortcut(.leftArrow, modifiers: .command)
                        
                        Button {
                            let result_interpreter = interpreter.interpretStepByStep(nil, index: interpreter.stepNumber + 1)
                            
                            if result_interpreter == false{
                                self.stopInterpreter()
                            }else if result_interpreter == nil{
                                self.stopInterpreter()
                            }
                        } label: {
                            Image(systemName: "arrow.turn.up.right")
                        }.keyboardShortcut(.rightArrow, modifiers: .command)
                    }
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
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
                        }.disabled(type == processor)
                    }
                }
            }
        }
    }
    
    private func stopInterpreter(){
        interpreter.instructions = []
        interpreter.stepNumber = 0
        interpreter.maximumStep = 0
        interpreter.runed = false
        interpreter.currentInstruction = nil
        runedStepByStep = false
    }
}

#Preview {
    Intel_x86_80186_UI()
}


enum ProcessorType: String, CaseIterable {
    case none = "No processor"
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


extension LanguageConfiguration {
    public static func intel_x86(_ languageService: LanguageServiceBuilder? = nil) -> LanguageConfiguration{
        return LanguageConfiguration(
            name: "Intel_x86",
            stringRegexp: "\"[^\"]*\"",
            characterRegexp: nil,
            numberRegexp: "(?:-)?(?:0[bB][01]+|0[xX][0-9a-fA-F]+|\\b\\d+\\b)",
            singleLineComment: ";",
            nestedComment: nil,
            identifierRegexp: "\\b([a-zA-Z]+)\\s*((?:[a-zA-Z0-9]+(?:,\\s*)?)*)\\b",
            reservedIdentifiers: X86Register.values() + OpCode.values()
        )
    }
}
