//
//  Modifier.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 20/01/2024.
//

import Foundation
import SwiftUI


struct ConsoleFilterButtonField: ViewModifier {
    
    @State var popOver = false
    
    @Binding var popOverResult: [ConsoleFilter]
    
    func body(content: Content) -> some View {
        HStack {
            Button {
                popOver.toggle()
            } label: {
                Image(systemName: popOverResult.isEmpty ? "circle.grid.3x3.circle" : "circle.grid.3x3.circle.fill")
            }.buttonStyle(.plain)
                .popover(isPresented: $popOver) {
                    VStack(alignment: .leading) {
                        ForEach(ConsoleFilter.allCases, id: \.self) { filter in
                            Button {
                                let index = popOverResult.firstIndex(of: filter)
                                
                                if let index = index{
                                    popOverResult.remove(at: index)
                                }else{
                                    popOverResult.append(filter)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: popOverResult.contains(filter) ? "checkmark.square.fill" : "square")
                                    
                                    Text(filter.rawValue)
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding()
                }
            
            content
        }
    }
}

enum ConsoleFilter: String, CaseIterable{
    case error = "Error"
    case warning = "Warning"
    case success = "Info"
    case debug = "Debug"
}

extension ConsoleFilter {
    static func getListColorFilter(filters: [ConsoleFilter]) -> [Color]{
        var result: [Color] = []
        
        for filter in filters {
            result.append(filter.getColorFilter())
        }
        
        return result
    }
    
    func getColorFilter() -> Color{
        switch self {
        case .error:
            return Color.red
        case .warning:
            return Color.orange
        case .success:
            return Color.green
        case .debug:
            return Color.blue
        }
    }
}


extension View {
    func consoleFilterButtonField(popOverResult: Binding<[ConsoleFilter]>) -> some View {
        modifier(ConsoleFilterButtonField(popOverResult: popOverResult))
    }
}
