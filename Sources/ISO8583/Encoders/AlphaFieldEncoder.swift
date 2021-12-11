//
//  AlphaFieldEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import Foundation

internal class AlphaFieldEncoder {
    
    static internal func encode(value: String, length: UInt, format: ISOStringFormat, fieldNumber: UInt = 0) throws -> Data {
        
        guard value.count == length else {
            throw ISOError.serializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(value.count)))
        }
        guard value.isConfirmToFormat(format) else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: format, actualValue: value))
        }
        guard let result = value.data(using: .ascii) else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber:fieldNumber, declaredFormat: format, actualValue: value))
        }
        return result
    }
    
    static internal func decode(data: Data, length: UInt, format: ISOStringFormat, fieldNumber: UInt = 0) throws -> (String, Data) {
        
        guard length > 0 else {
            return ("", data)
        }
        guard data.count >= length else {
            throw ISOError.deserializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(data.count)))
        }
        guard let value = String(data: data.subdata(in: Range(0...Int(length - 1))), encoding: .ascii) else {
            let hexString = data.subdata(in: Range(0...Int(length - 1))).map { String(format: "%02X", $0) }.joined()
            throw ISOError.deserializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: format, actualValue: hexString))
        }
        guard value.isConfirmToFormat(format) else {
            throw ISOError.deserializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: format, actualValue: value))
        }
        let restData = data.count > length ? data.subdata(in: Range(Int(length)...data.count - 1)) : Data()
        return (value, restData)
    }
}
