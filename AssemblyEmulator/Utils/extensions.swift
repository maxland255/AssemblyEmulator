//
//  extensions.swift
//  AssemblyEmulator
//
//  Created by Harry Pieteraerens on 06/02/2024.
//

import Foundation


extension Array{
    func isOnlyTabs() -> Bool{
        if self.isEmpty{
            return false
        }
        
        for element in self{
            if let element = element as? String{
                if element != "\t" {
                    return false
                }
            }
        }
        
        return true
    }
}
