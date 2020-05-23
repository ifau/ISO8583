//
//  ISOMessage.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public final class ISOMessage {
    
    /// Message type identifier
    public var mti: UInt = 0
    /// Message fields. Dictionary in wich key is field number, value is field value
    public var fields : [UInt:String] = [:]

    /// Initialize `ISOMessage` object with default `mti` and `fields` values
    public init() {
        
    }
    
    /// Initialize `ISOMessage` object with provided `mti` and `fields` values
    /// - Parameters:
    ///   - mti: Message type identifier
    ///   - fields: Message fields. Dictionary in wich key is field number, value is field value
    public convenience init(mti: UInt, fields: [UInt:String]) {
        self.init()
        self.mti = mti
        self.fields = fields
    }
}

extension ISOMessage : Equatable {
    
    static public func == (lhs: ISOMessage, rhs: ISOMessage) -> Bool {
        guard lhs.mti == rhs.mti else {
            return false
        }
        guard lhs.fields == rhs.fields else {
            return false
        }
        return true
    }
}

extension ISOMessage : CustomStringConvertible {
    
    public var description: String {
        var result = "\n[mti : \(mti)]\n"
        for key in fields.keys.sorted() {
            result.append("[\(key) : \(fields[key] ?? "")]\n")
        }
        return result
    }
}
