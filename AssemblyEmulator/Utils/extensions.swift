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

extension UInt{
    func toInt() -> Int{
        return Int(self)
    }
}

extension Int{
    func toUInt() -> UInt{
        return UInt(self)
    }
}
