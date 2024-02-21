//
//  AssemblyEmulatorApp.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 17/01/2024.
//

import SwiftUI

@main
struct AssemblyEmulatorApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, idealWidth: 1000, maxWidth: .infinity, minHeight: 550, idealHeight: 550, maxHeight: .infinity)
        }.defaultSize(CGSize(width: 1000, height: 550))
            .commands {
                CommandGroup(replacing: .appInfo) {
                    Button {
                        appDelegate.toggleAboutWindow()
                    } label: {
                        Text("About \(NSApplication.appName)")
                    }
                }
                
                CommandMenu("Info") {
                    Button("Assembly") {
                        appDelegate.toogleAssemblyInfoWindow()
                    }
                }
            }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate{
        
    private var aboutWindow: NSWindowController?
    
    func toggleAboutWindow(){
        if self.aboutWindow == nil{
            let styleMark: NSWindow.StyleMask = [.closable, .titled]
            let window = NSWindow()
            
            window.styleMask = styleMark
            window.title = "About \(NSApplication.appName)"
            window.titlebarAppearsTransparent = true
            window.center()
            window.contentView = NSHostingView(rootView: AboutWindow())
            window.backgroundColor = .controlBackgroundColor
            
            self.aboutWindow = NSWindowController(window: window)
        }
        
        self.aboutWindow?.showWindow(self.aboutWindow?.window)
    }
    
    // Assembly information window
    private var assemblyInfoWindow: NSWindowController?
    
    func toogleAssemblyInfoWindow(){
        if self.assemblyInfoWindow == nil{
            let styleMask: NSWindow.StyleMask = [.closable, .titled]
            let window = NSWindow()
            
            window.styleMask = styleMask
            window.title = "About Assembly in \(NSApplication.appName)"
            window.titlebarAppearsTransparent = true
            window.center()
            window.contentView = NSHostingView(rootView: Assembly())
            window.backgroundColor = .controlBackgroundColor
            
            self.assemblyInfoWindow = NSWindowController(window: window)
        }
        
        self.assemblyInfoWindow?.showWindow(self.assemblyInfoWindow?.window)
    }
}


extension NSApplication{
    static var appVersion: String{
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Error"
    }
    
    static var buildVersion: String{
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Error"
    }
    
    static var appName: String{
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Error"
    }
    
    static var minimumOSVersion: String{
        return Bundle.main.object(forInfoDictionaryKey: "MinimumOSVersion") as? String ?? "Error"
    }
    
    static var supportedPlatforms: Array<String>{
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleSupportedPlatforms") as? Array ?? ["Error"]
    }
    
    static var localizations: Array<String>{
        return Bundle.main.localizations
    }
    
    static var developmentLocalization: String?{
        return Bundle.main.developmentLocalization
    }
    
    static var beta: String{
        #if DEBUG
        return "Development"
        #else
        if let url = Bundle.main.appStoreReceiptURL{
            if url.lastPathComponent == "sandboxReceipt"{
                return "Beta"
            }else{
                return "Release"
            }
        }else{
            return "Error"
        }
        #endif
    }
}
