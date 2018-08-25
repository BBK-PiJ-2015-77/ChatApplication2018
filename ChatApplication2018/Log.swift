//
//  Log.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 25/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//
//https://medium.com/@sauvik_dolui/developing-a-tiny-logger-in-swift-7221751628e6

import Foundation

enum verbosity: Int {
    case none = 0
    case low = 1
    case high = 2
    
    static let allValues = [0,1,2]
}

class Log {
    
    static var dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    class func print(_ object: Any, loggingVerbosity: verbosity) {
        var verbosityLevel: Int
        
        let possibleVerbosityValues = verbosity.allValues
        
        if possibleVerbosityValues.contains(Global.verbosity) {
            verbosityLevel = Global.verbosity
        } else {
            verbosityLevel = 0
        }
        
        if loggingVerbosity.rawValue <= verbosityLevel {
            Swift.print("\(Date().toString()): \(object)")
        }
    }
}

internal extension Date {
    func toString() -> String {
        return Log.dateFormatter.string(from: self as Date)
    }
}
