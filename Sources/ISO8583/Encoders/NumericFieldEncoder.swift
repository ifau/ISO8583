//
//  NumericFieldEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import Foundation

internal class NumericFieldEncoder {
    
    static internal func encode(value: String, length: UInt, padding: ISOPaddingFormat, fieldNumber: UInt = 0) throws -> Data {
        
        guard value.count == length else {
            throw ISOError.serializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(value.count)))
        }
        guard value.isConfirmToFormat(.n) else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: .n, actualValue: value))
        }
        
        var chars = Array(value)
        if length % 2 == 1 {
            switch padding {
            case .left:
                chars.insert("0", at: 0)
            case .right:
                chars.append("0")
            }
        }
        
        let result: [UInt8] = stride(from: 0, to: chars.count, by: 2)
            .map { UInt8(String([chars[$0], chars[$0+1]]), radix: 16) }
            .compactMap{ $0 }
        return Data(result)
    }
    
    static internal func decode(data: Data, length: UInt, padding: ISOPaddingFormat, fieldNumber: UInt = 0) throws -> (String, Data) {
        
        guard length > 0 else {
            return ("", data)
        }
        
        let numberOfBytesToRead : UInt = (length % 2 == 1) ? ((length + 1) / 2) : (length / 2)

        guard data.count >= numberOfBytesToRead else {
            throw ISOError.deserializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(data.count * 2)))
        }
        
        var value = data.subdata(in: Range(0...Int(numberOfBytesToRead - 1))).map { String(format: "%02X", $0) }.joined()
        if value.count > length {
            switch padding {
            case .left:
                value.removeFirst()
            case .right:
                value.removeLast()
            }
        }
        
        guard value.isConfirmToFormat(.n) else {
            throw ISOError.deserializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: .n, actualValue: value))
        }
        
        let restData = data.count > numberOfBytesToRead ? data.subdata(in: Range(Int(numberOfBytesToRead)...data.count - 1)) : Data()
        return (value, restData)
    }
}
