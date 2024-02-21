//
//  Intel_x86_UI.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import SwiftUI
import CodeEditorView
import LanguageSupport

struct Intel_x86_UI: View {
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    @ObservedObject var interpreter = Asmx86Interpreter()
    
    @State var parser = Asmx86Parser()
    
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
                            
                            Text("Current line: \"\(currentInstruction.lineValue.replacingOccurrences(of: "\t", with: ""))\" (line number: \(currentInstruction.lineNumber))")
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
                    layout: CodeEditor.LayoutConfiguration(showMinimap: false, wrapText: true)
                )
                    .environment(\.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
                
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
                                                
                        if !instructions.0.isEmpty || !instructions.1.isEmpty{
                            interpreter.interpret(instructions.0, instructions.1, strict: processor != .none)
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
                                                                
                        if !instructions.0.isEmpty || !instructions.1.isEmpty{
                            self.runedStepByStep = true
                            let result_interpreter = interpreter.interpretStepByStep(instructions.0, instructions.1, strict: processor != .none)
                                                        
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
                        }.keyboardShortcut("k", modifiers: .command)
                            .help("Kill program (Command + k)")
                        
                        Button {
                            // Reset all register
                            switch processor {
                            case .none:
                                interpreter.registers = [:]
                            case .intel_80186, .intel_80286:
                                interpreter.registers = processor.getProcessorRegister()
                            }
                            
                            let result_interpreter = interpreter.interpretStepByStep(nil, nil, index: interpreter.stepNumber - 1)
                            
                            if result_interpreter == false{
                                self.stopInterpreter()
                            }
                        } label: {
                            Image(systemName: "arrow.turn.up.left")
                        }.disabled(interpreter.stepNumber == 0)
                            .keyboardShortcut(.leftArrow, modifiers: .command)
                            .help("Kill program (Command + <-)")
                        
                        Button {
                            // Reset all register
                            switch processor {
                            case .none:
                                interpreter.registers = [:]
                            case .intel_80186, .intel_80286:
                                interpreter.registers = processor.getProcessorRegister()
                            }
                            
                            let result_interpreter = interpreter.interpretStepByStep(nil, nil, index: interpreter.stepNumber + 1)
                            
                            if result_interpreter == false{
                                self.stopInterpreter()
                            }else if result_interpreter == nil{
                                self.stopInterpreter()
                            }
                        } label: {
                            Image(systemName: "arrow.turn.up.right")
                        }.keyboardShortcut(.rightArrow, modifiers: .command)
                            .help("Kill program (Command + ->)")
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
        interpreter.funcInstructions = [:]
        interpreter.stepNumber = 0
        interpreter.maximumStep = 0
        interpreter.runed = false
        interpreter.currentInstruction = nil
        interpreter.executeInstructions = 0
        interpreter.executeFuncInstructions = 0
        runedStepByStep = false
    }
}

#Preview {
    Intel_x86_UI()
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
            stringRegexp: "\"(.*?)\"",
            characterRegexp: nil,
            numberRegexp: "^[0-9]+(b|h)?$",
            singleLineComment: ";",
            nestedComment: nil,
            identifierRegexp: "\\b([a-zA-Z]+\\s+)(?:([a-zA-Z0-9]+(?:,\\s*)?)*)\\b|\\b\\s*\\b",
            reservedIdentifiers: X86Register.values() + OpCode.values()
        )
    }
}
