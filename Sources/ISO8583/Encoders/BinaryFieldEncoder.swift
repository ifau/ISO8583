//
//  BinaryFieldEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import Foundation

internal class BinaryFieldEncoder {
    
    static internal func encode(value: String, length: UInt, fieldNumber: UInt = 0) throws -> Data {
        
        guard value.count % 2 == 0, value.isConfirmToFormat(.hex) else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: .hex, actualValue: value))
        }
        guard value.count == (length * 2) else {
            throw ISOError.serializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(value.count / 2)))
        }
        
        let chars = Array(value)
        let result: [UInt8] = stride(from: 0, to: chars.count, by: 2)
            .map { UInt8(String([chars[$0], chars[$0+1]]), radix: 16) }
            .compactMap{ $0 }
        return Data(result)
    }
    
    static internal func decode(data: Data, length: UInt, fieldNumber: UInt = 0) throws -> (String, Data) {
        
        guard length > 0 else {
            return ("", data)
        }
        guard data.count >= length else {
            throw ISOError.deserializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(data.count)))
        }
        let value = data.subdata(in: Range(0...Int(length - 1)))
        let hexString = value.map { String(format: "%02X", $0) }.joined()
        let restData = data.count > length ? data.subdata(in: Range(Int(length)...data.count - 1)) : Data()
        return (hexString, restData)
    }
}
