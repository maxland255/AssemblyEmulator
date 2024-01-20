//
//  AboutWindow.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 18/01/2024.
//

import SwiftUI

struct AboutWindow: View {
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        HStack {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 125, height: 125)
                .padding()
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 5) {
                Text(NSApplication.appName)
                    .font(.title.bold())
                    .textSelection(.enabled)
                        
                Text("Version: " + NSApplication.appVersion + "   Build: " + NSApplication.buildVersion + "  " + NSApplication.beta)
                    .font(.callout)
                    .foregroundColor(.secondary)
                                        
                Text("AssemblyEmulator is an application designed to emulate assembly language. The primary goal is to simulate registers and RAM memory, utilizing an interpreter to execute assembly code and interact with the simulated registers and memory.")
                    .font(.body)
                        
                Spacer()
                        
                HStack(spacing: 10) {
                    Button {
                        openURL(URL(string: "https://pieteraerens.eu")!)
                    } label: {
                        Text("WebSite")
                    }
                    
                    Button {
                        openURL(URL(string: "https://github.com/maxland255/AssemblyEmulator/blob/main/LICENCE")!)
                    } label: {
                        Text("Licence")
                    }
                
                    Spacer()
                }
            
                Spacer()
                
                Text("Copyright © 2024 pieteraerens.eu")
                    .font(.caption)
                    .textSelection(.enabled)
            }.padding()
        
            Spacer()
        
        }.frame(width: 500, height: 250)
    }
}

#Preview {
    AboutWindow()
}
