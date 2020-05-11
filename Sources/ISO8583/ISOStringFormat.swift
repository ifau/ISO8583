//
//  ISOStringFormat.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 10/05/2020.
//

import Foundation

public struct ISOStringFormat: OptionSet {
    
    /// Alphabetical characters, A through Z and a through z
    public static let a = ISOStringFormat(rawValue: 1 << 0)
    /// Numeric digits, 0 through 9
    public static let n = ISOStringFormat(rawValue: 1 << 1)
    /// Special characters
    public static let s = ISOStringFormat(rawValue: 1 << 2)
    /// Pad character, space
    public static let p = ISOStringFormat(rawValue: 1 << 3)
    /// Sign of amount.  'C' to indicate a positive value, or 'D' to indicate a negative value
    public static let x = ISOStringFormat(rawValue: 1 << 4)
    /// Track 2 characters set
    public static let z = ISOStringFormat(rawValue: 1 << 5)
    /// Numeric digits 0 through 9 and alphabetical characters, A through F
    internal static let hex = ISOStringFormat(rawValue: 1 << 6)
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension ISOStringFormat : CustomStringConvertible {
    
    public var description: String {
        var result = ""
        
        if self.contains(.a) {
            result.append("a")
        }
        
        if self.contains(.n) {
            result.append("n")
        }
        
        if self.contains(.s) {
            result.append("s")
        }
        
        if self.contains(.p) {
            result.append("p")
        }
        
        if self.contains(.x) {
            result.append("x")
        }
        
        if self.contains(.z) {
            result.append("z")
        }
        
        if self.contains(.hex) {
            result.append("_hex_")
        }
        
        if self.subtracting([.a, .n, .s, .p, .x, .z, .hex]).rawValue != 0 {
            result.append("_unknown_")
        }
        
        return result
    }
}

extension String {
    
    internal func isConfirmToFormat(_ format: ISOStringFormat) -> Bool {
        
        var characterSet = CharacterSet()
        
        if format.contains(.a) {
            characterSet.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            characterSet.insert(charactersIn: "abcdefghijklmnopqrstuvwxyz")
        }
        
        if format.contains(.n) {
            characterSet.insert(charactersIn: "0123456789")
        }
        
        if format.contains(.s) {
            //  !"#$%&'()*+,-./
            characterSet.insert(charactersIn:(32...47).compactMap { String(UnicodeScalar.init($0)) }.joined())
            // :;<=>?@
            characterSet.insert(charactersIn:(58...64).compactMap { String(UnicodeScalar.init($0)) }.joined())
            // [\]^_`
            characterSet.insert(charactersIn:(91...96).compactMap { String(UnicodeScalar.init($0)) }.joined())
            // {|}~
            characterSet.insert(charactersIn:(123...126).compactMap { String(UnicodeScalar.init($0)) }.joined())
        }
        
        if format.contains(.p) {
            characterSet.insert(charactersIn: " ")
        }
        
        if format.contains(.x) {
            characterSet.insert(charactersIn: "CD")
        }
        
        if format.contains(.z) {
            characterSet.insert(charactersIn: ";0123456789=?")
        }
        
        if format.contains(.hex) {
            characterSet.insert(charactersIn: "0123456789abcdefABCDEF")
        }
        
        return (self.rangeOfCharacter(from: characterSet.inverted) == nil)
    }
}
