//
//  ISOMessage.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public final class ISOMessage {

    var mti: UInt = 0
    var fields : [UInt:String] = [:]
    
    convenience init(mti: UInt, fields: [UInt:String]) {
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
