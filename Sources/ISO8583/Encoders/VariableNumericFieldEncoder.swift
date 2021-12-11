//
//  VariableNumericFieldEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import Foundation

internal class VariableNumericFieldEncoder {
    
    static internal func encode(value: String, numberOfBytesForLength: UInt, lengthFormat: ISONumberFormat, padding: ISOPaddingFormat, fieldNumber: UInt = 0) throws -> Data {
        
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
        
        guard value.isConfirmToFormat(.n) else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: .n, actualValue: value))
        }
        
        var chars = Array(value)
        if value.count % 2 == 1 {
            switch padding {
            case .left:
                chars.insert("0", at: 0)
            case .right:
                chars.append("0")
            }
        }
        let numberOfBytesForValue = chars.count / 2
        
        guard numberOfBytesForValue <= maximumNumberOfBytesForValue else {
            throw ISOError.serializeMessageFailed(reason: .fieldValueIsMoreThanMaximumLengthForDeclaredFormat(fieldNumber: fieldNumber, maximumLength: UInt(maximumNumberOfBytesForValue), actualLength: UInt(numberOfBytesForValue)))
        }
        
        let encodedValue: [UInt8] = stride(from: 0, to: chars.count, by: 2)
            .map { UInt8(String([chars[$0], chars[$0+1]]), radix: 16) }
            .compactMap{ $0 }
        
        let encodedLength = try LengthEncoder.encode(UInt(value.count), numberOfBytes: numberOfBytesForLength, format: lengthFormat)
        result.append(encodedLength)
        result.append(Data(encodedValue))
        return result
    }
    
    static internal func decode(data: Data, numberOfBytesForLength: UInt, lengthFormat: ISONumberFormat, padding: ISOPaddingFormat, fieldNumber: UInt = 0) throws -> (String, Data) {
        
        let lengthLength = Int(numberOfBytesForLength)
        var valueLength = 0
        
        guard data.count >= lengthLength else {
            throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeFieldLength(fieldNumber: fieldNumber))
        }
        
        valueLength = Int(try LengthEncoder.decode(from: data.subdata(in: Range(0...lengthLength - 1)), format: lengthFormat))
        
        var numberOfBytesForValue = 0
        if valueLength > 0 {
            numberOfBytesForValue = (valueLength % 2 == 1) ? ((valueLength + 1) / 2) : (valueLength / 2)
        }
        
        guard data.count >= lengthLength + numberOfBytesForValue else {
            let fieldLength : UInt = (data.count - lengthLength >= 0) ? UInt(data.count - lengthLength) * 2 : 0
            throw ISOError.deserializeMessageFailed(reason: .fieldValueIsLessThanDecodedLength(fieldNumber: fieldNumber, decodedLength: UInt(valueLength), actualLength: fieldLength))
        }
        guard numberOfBytesForValue > 0 else {
            let restData = data.count > lengthLength ? data.subdata(in: Range(lengthLength...data.count - 1)) : Data()
            return ("", restData)
        }
        
        var value = data.subdata(in: Range(lengthLength...lengthLength + numberOfBytesForValue - 1)).map { String(format: "%02X", $0) }.joined()
        
        if valueLength < value.count {
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
        
        let restData = data.count > lengthLength + numberOfBytesForValue ? data.subdata(in: Range((lengthLength + numberOfBytesForValue)...data.count - 1)) : Data()
        return (value, restData)
    }
}
