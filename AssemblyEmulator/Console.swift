//
//  Console.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import Foundation
import SwiftUI


class ConsoleLine: ObservableObject {
    @Published var line = [Console]()
    
    static let shared = ConsoleLine()
    
    private init() { }
    
    func appendLine(_ programm: String, _ value: String, color: Color = Color.white) {
        line.append(Console(color: color, programm: programm, value: value))
    }
    
    func error(_ programm: String, _ value: String) {
        line.append(Console(color: .red, programm: "\(programm) (ERROR)", value: value))
    }
    
    func debug(_ programm: String, _ value: String) {
        line.append(Console(color: .blue, programm: "\(programm) (DEBUG)", value: value))
    }
    
    func warning(_ programm: String, _ value: String) {
        line.append(Console(color: .orange, programm: "\(programm) (WARNING)", value: value))
    }
    
    func info(_ programm: String, _ value: String) {
        line.append(Console(color: .green, programm: "\(programm) (INFO)", value: value))
    }
    
    static func error(_ programm: String, _ value: String) {
        self.shared.line.append(Console(color: .red, programm: "\(programm) (ERROR)", value: value))
    }
    
    static func debug(_ programm: String, _ value: String) {
        self.shared.line.append(Console(color: .blue, programm: "\(programm) (DEBUG)", value: value))
    }
    
    static func warning(_ programm: String, _ value: String) {
        self.shared.line.append(Console(color: .orange, programm: "\(programm) (WARNING)", value: value))
    }
    
    static func info(_ programm: String, _ value: String) {
        self.shared.line.append(Console(color: .green, programm: "\(programm) (INFO)", value: value))
    }
    
    static func error(error: x86Error) {
        self.shared.line.append(Console(color: .red, programm: "\(error.program) (ERROR)", value: error.getErrorString()))
    }
}


struct Console: Hashable {
    let id = UUID().uuidString
    let color: Color
    let programm: String
    let value: String
    var search: String {
        programm.lowercased() + value.lowercased()
    }
}


//Console View
struct ConsoleView: View {    
    @ObservedObject var lines = ConsoleLine.shared
    
    @State var filterText = ""
    
    @State var viewHeight: CGFloat = 200
    
    @State var popOverResult: [ConsoleFilter] = []
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .frame(height: 2)
                .onHover(perform: { hovered in
                    if hovered{
                        NSCursor.resizeUpDown.push()
                    }else{
                        NSCursor.resizeUpDown.pop()
                    }
                })
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged({ value in
                            let height = CGFloat(integerLiteral: Int(value.translation.height))
                                                        
                            if viewHeight - height >= 200 && viewHeight - height <= 400{
                                viewHeight -= height
                            }
                        })
                )
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundStyle(Color.black)
                
                VStack (spacing: 7.5) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            ForEach(lines.line.filter({filterText.isEmpty ? true : $0.search.lowercased().contains(filterText.lowercased())}), id: \.self) {line in
                                if popOverResult.isEmpty ? true : popOverResult.contains(where: { color in color.getColorFilter() == line.color}) {
                                    HStack {
                                        Text("[\(line.programm)]: \(line.value)")
                                            .foregroundStyle(line.color)
                                            .font(Font.system(size: 13, design: .monospaced))
                                            .textSelection(.enabled)
                                            .padding(2.5)
                                            .id(line.id)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }.onChange(of: lines.line) {
                            proxy.scrollTo(lines.line.last?.id ?? "", anchor: .bottom)
                        }
                    }
                    
                    VStack(spacing: 0) {
                        Divider()
                        
                        ZStack {
                            Rectangle()
                                .foregroundStyle(.background)
                            
                            HStack(spacing: 16) {
                                Spacer()
                                
                                TextField("Filter", text: $filterText)
                                    .textFieldStyle(.roundedBorder)
                                    .consoleFilterButtonField(popOverResult: $popOverResult)
                                    .frame(width: 300)
                                
                                Button {
                                    lines.line = []
                                } label: {
                                    Image(systemName: "trash")
                                }.buttonStyle(.plain)
                                    .disabled(lines.line.isEmpty)
                            }.padding(.horizontal)
                        }.frame(height: 30)
                    }
                }
            }
        }.frame(height: viewHeight)
    }
}
