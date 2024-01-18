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
}


struct Console: Hashable {
    let id = UUID().uuidString
    let color: Color
    let programm: String
    let value: String
}


//Console View
struct ConsoleView: View {
    @ObservedObject var lines = ConsoleLine.shared
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundStyle(Color.black)
            
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(lines.line, id: \.self) {line in
                        HStack {
                            Text("[\(line.programm)]: \(line.value)")
                                .foregroundStyle(line.color)
                                .textSelection(.enabled)
                                .padding(2.5)
                                .id(line.id)
                            
                            Spacer()
                        }
                    }
                }.onChange(of: lines.line) {
                    proxy.scrollTo(lines.line.last?.id ?? "", anchor: .bottom)
                }
            }
        }
    }
}
