//
//  VariableAlphaFieldEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import Foundation

internal class VariableAlphaFieldEncoder {
    
    static internal func encode(value: String, numberOfBytesForLength: UInt, lengthFormat: ISONumberFormat, valueFormat: ISOStringFormat, fieldNumber: UInt = 0) throws -> Data {
        
        var result = Data()
        var maximumNumberOfBytesForValue = 0
        
        switch lengthFormat {
        case .bcd:
            // 99 for 1 byte, 9999 for 2 bytes
            maximumNumberOfBytesForValue = Int(pow(Double(10), Double(2*numberOfBytesForLength))) - 1
        case .ascii:
            // 99 for 2 bytes, 999 for 3 bytes
            maximumNumberOfBytesForValue = Int(pow(Double(10), Double(numberOfBytesForLength))) - 1
        }
        
        guard value.isConfirmToFormat(valueFormat) else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: valueFormat, actualValue: value))
        }
        guard let encodedValue = value.data(using: .ascii) else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: valueFormat, actualValue: value))
        }
        guard encodedValue.count <= maximumNumberOfBytesForValue else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsMoreThanMaximumLengthForDeclaredFormat(fieldNumber: fieldNumber, maximumLength: UInt(maximumNumberOfBytesForValue), actualLength: UInt(encodedValue.count)))
        }
        
        let encodedLength = try LengthEncoder.encode(UInt(encodedValue.count), numberOfBytes: numberOfBytesForLength, format: lengthFormat)
        result.append(encodedLength)
        result.append(encodedValue)
        return result
    }
    
    static internal func decode(data: Data, numberOfBytesForLength: UInt, lengthFormat: ISONumberFormat, valueFormat: ISOStringFormat, fieldNumber: UInt = 0) throws -> (String, Data) {
        
        let lengthLength = Int(numberOfBytesForLength)
        var valueLength: Int = 0
        
        guard data.count >= lengthLength else {
            throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeFieldLength(fieldNumber: fieldNumber))
        }
        
        valueLength = Int(try LengthEncoder.decode(from: data.subdata(in: Range(0...lengthLength - 1)), format: lengthFormat))
        
        guard data.count >= lengthLength + valueLength else {
            let fieldLength : UInt = (data.count - lengthLength >= 0) ? UInt(data.count - lengthLength) : 0
            throw ISOError.deserializeMessageFailed(reason: .fieldValueIsLessThanDecodedLength(fieldNumber: fieldNumber, decodedLength: UInt(valueLength), actualLength: fieldLength))
        }
        guard valueLength > 0 else {
            let restData = data.count > lengthLength ? data.subdata(in: Range(lengthLength...data.count - 1)) : Data()
            return ("", restData)
        }
        guard let value = String(data: data.subdata(in: Range(lengthLength...lengthLength + valueLength - 1)), encoding: .ascii) else {
            let hexString = data.subdata(in: Range(lengthLength...lengthLength + valueLength - 1)).map { String(format: "%02X", $0) }.joined()
            throw ISOError.deserializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: valueFormat, actualValue: hexString))
        }
        guard value.isConfirmToFormat(valueFormat) else {
            throw ISOError.deserializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: valueFormat, actualValue: value))
        }
        let restData = data.count > lengthLength + valueLength ? data.subdata(in: Range((lengthLength + valueLength)...data.count - 1)) : Data()
        return (value, restData)
    }
}
