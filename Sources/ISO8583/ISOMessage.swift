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
    /// Message fields. Dictionary in which key is field number, value is the field value
    public var fields : [UInt:String] = [:]

    /// Initialize `ISOMessage` object with default `mti` and `fields` values
    public init() {
        
    }
    
    /// Initialize `ISOMessage` object with provided `mti` and `fields` values
    /// - Parameters:
    ///   - mti: Message type identifier
    ///   - fields: Message fields. Dictionary in which key is field number, value is the field value
    public convenience init(mti: UInt, fields: [UInt:String]) {
        self.init()
        self.mti = mti
        self.fields = fields
    }
    
    /// Initialize `ISOMessage` object from binary message according to the provided scheme
    /// - Parameters:
    ///   - data: `Data` that contains bytes of the serialized message
    ///   - scheme: `ISOScheme` which describes a protocol that will be used to deserialize the message
    /// - Throws: `ISOError.deserializeMessageFailed(reason)`, see the reason for details
    public convenience init(data: Data, using scheme: ISOScheme) throws {
        let message = try ISOMessageDeserializer().deserialize(data: data, scheme: scheme)
        self.init()
        self.mti = message.mti
        self.fields = message.fields
    }
    
    /// Serialize the `ISOMessage` object into a binary message according to the provided scheme
    /// - Parameters:
    ///   - scheme: `ISOScheme` which describes a protocol that will be used to serialize the message
    /// - Throws: `ISOError.serializeMessageFailed(reason)`, see the reason for details
    /// - Returns: Data of the serialized message
    public func data(using scheme: ISOScheme) throws -> Data {
        return try ISOMessageSerializer().serialize(message: self, scheme: scheme)
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
