//
//  ISOMessageDeserializer.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public final class ISOMessageDeserializer {
    
    public init() {
        
    }
    
    /// Deserialize binary message according to provided scheme
    /// - Parameters:
    ///   - data: `Data` which contains bytes of serialized message
    ///   - scheme: `ISOScheme` which describe protocol that will be used for deserialize message
    /// - Throws: `ISOError.deserializeMessageFailed(reason)`, see reason for details
    /// - Returns: Deserialized `ISOMessage` object
    public func deserialize(data: Data, scheme: ISOScheme) throws -> ISOMessage {
        
        let message = ISOMessage()
        var tempData = Data()
        
        let numberOfBytesForLength = scheme.numberOfBytesForLength()
        
        if numberOfBytesForLength > 0 {
            
            guard data.count > numberOfBytesForLength else {
                throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeMessageLength)
            }
            
            let messageLength = try readLength(data: data.subdata(in: Range(0...Int(numberOfBytesForLength - 1))), format: scheme.lengthFormat())
            
            guard messageLength > 0 else {
                let actual : UInt = UInt(data.count) - numberOfBytesForLength >= 0 ? UInt(data.count) - numberOfBytesForLength : 0
                throw ISOError.deserializeMessageFailed(reason: .messageIsLessThanDecodedLength(decodedLength: messageLength, actualLength: actual))
            }
            
            guard data.count >= numberOfBytesForLength + messageLength else {
                let actual : UInt = UInt(data.count) - numberOfBytesForLength >= 0 ? UInt(data.count) - numberOfBytesForLength : 0
                throw ISOError.deserializeMessageFailed(reason: .messageIsLessThanDecodedLength(decodedLength: messageLength, actualLength: actual))
            }
            
            tempData = data.subdata(in: Range(Int(numberOfBytesForLength)...Int(messageLength + numberOfBytesForLength - 1)))
        } else {
            tempData = data
        }
        
        let (mti, restDataAfterReadMTI) = try readMTI(data: tempData, format: scheme.mtiFormat())
        tempData = restDataAfterReadMTI
        message.mti = mti
        
        let (bitmap, restDataAfterReadBitmap) = try readBitmap(data: tempData)
        tempData = restDataAfterReadBitmap
        
        for (byteIndex, byteValue) in bitmap.enumerated() {
            
            for bitIndex in 0...8 {
                guard (0b10000000 & (byteValue << bitIndex)) > 0 else { continue }
                let fieldNumber = UInt(bitIndex + (byteIndex * 8) + 1)
                guard fieldNumber != 1, fieldNumber != 65, fieldNumber != 129 else { continue }
                
                let fieldFormat = scheme.fieldFormat(for: fieldNumber)
                let (fieldData, restData) = try readField(fieldNumber: fieldNumber, data: tempData, format: fieldFormat)
                tempData = restData
                message.fields[fieldNumber] = fieldData
            }
        }
        
        return message
    }
    
    internal func readLength(data: Data, format: ISONumberFormat) throws -> UInt {
        
        switch format {
        case .bcd:
            var value : UInt = 0
            var power : UInt = 1
            for (_, byteValue) in data.enumerated().reversed() {
                /// Check byte contain only numbers 0 1 2 3 4 5 6 7 8 9, without a b c d e f
                let mask8 = byteValue & 0x88; let mask4 = byteValue & 0x44; let mask2 = byteValue & 0x22
                guard ((mask8 >> 2) & ((mask4 >> 1) | mask2) == 0) else {
                    let hexString = data.map { String(format: "%02X", $0) }.joined()
                    throw ISOError.deserializeMessageFailed(reason: .lengthIsNotConformToDeclaredFormat(declaredFormat: "bcd", actualValue: hexString))
                }
                value += UInt(byteValue & 0x0f) * power;
                power *= 10;
                value += UInt((byteValue & 0xf0) >> 4) * power;
                power *= 10;
            }
            return value
        case .ascii:
            guard let string = String(data: data, encoding: .ascii), let value = UInt(string) else {
                let hexString = data.map { String(format: "%02X", $0) }.joined()
                throw ISOError.deserializeMessageFailed(reason: .lengthIsNotConformToDeclaredFormat(declaredFormat: "ascii", actualValue: hexString))
            }
            return value
        }
    }
    
    internal func readMTI(data: Data, format: ISONumberFormat) throws -> (UInt, Data) {
        
        var mti : UInt
        var restData : Data
        var mtiLength : Int
        
        switch format {
        case .bcd:
            mtiLength = 2
        case .ascii:
            mtiLength = 4
        }
        
        guard data.count >= mtiLength else {
            throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeMTI)
        }
        
        mti = try readLength(data: data.subdata(in: Range(0...mtiLength - 1)), format: format)
        restData = mtiLength < data.count ? data.subdata(in: Range(mtiLength...data.count - 1)) : Data()
        return (mti, restData)
    }
    
    
    internal func readBitmap(data: Data) throws -> ([UInt8], Data) {
        
        guard data.count >= 8 else {
            throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodePrimaryBitmap)
        }
        
        var bitmap : [UInt8] = []
        var restData : Data
        
        bitmap += data.subdata(in: Range(0...7))
        restData = data.count > 8 ? data.subdata(in: Range(8...data.count - 1)) : Data()
        
        guard let firstByte = bitmap.first, firstByte >= 0b10000000 else {
            return (bitmap, restData)
        }
        
        guard data.count >= 16 else {
            throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeSecondaryBitmap)
        }
        
        bitmap += data.subdata(in: Range(8...15))
        restData = data.count > 16 ? data.subdata(in: Range(16...data.count - 1)) : Data()
        return (bitmap, restData)
    }
    
    internal func readField(fieldNumber: UInt = 0, data: Data, format: ISOFieldFormat) throws -> (String, Data) {
        
        switch format {
        case .alpha(let length, let valueFormat):
            
            guard length > 0 else {
                return ("", data)
            }
            guard data.count >= length else {
                throw ISOError.deserializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(data.count)))
            }
            guard let value = String(data: data.subdata(in: Range(0...Int(length - 1))), encoding: .ascii) else {
                let hexString = data.subdata(in: Range(0...Int(length - 1))).map { String(format: "%02X", $0) }.joined()
                throw ISOError.deserializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: valueFormat, actualValue: hexString))
            }
            guard value.isConfirmToFormat(valueFormat) else {
                throw ISOError.deserializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: valueFormat, actualValue: value))
            }
            let restData = data.count > length ? data.subdata(in: Range(Int(length)...data.count - 1)) : Data()
            return (value, restData)
            
        case .binary(let length):
            
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
        
        case .numeric(let length, let padding):
            
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
            
        case .llvar(let lengthFormat, let valueFormat), .lllvar(let lengthFormat, let valueFormat):
            
            var lengthLength = 0
            var valueLength = 0
            
            switch lengthFormat {
            case .bcd:
                lengthLength = 1
                if case .lllvar(_, _) = format {
                    lengthLength = 2
                }
            case .ascii:
                lengthLength = 2
                if case .lllvar(_, _) = format {
                    lengthLength = 3
                }
            }
            
            guard data.count >= lengthLength else {
                throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeFieldLength(fieldNumber: fieldNumber))
            }
            
            valueLength = try Int(readLength(data: data.subdata(in: Range(0...lengthLength - 1)), format: lengthFormat))
            
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
            
        case .llbin(let lengthFormat), .lllbin(let lengthFormat):
            
            var lengthLength = 0
            var valueLength = 0
            
            switch lengthFormat {
            case .bcd:
                lengthLength = 1
                if case .lllbin(_) = format {
                    lengthLength = 2
                }
            case .ascii:
                lengthLength = 2
                if case .lllbin(_) = format {
                    lengthLength = 3
                }
            }
            
            guard data.count >= lengthLength else {
                throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeFieldLength(fieldNumber: fieldNumber))
            }
            
            valueLength = try Int(readLength(data: data.subdata(in: Range(0...lengthLength - 1)), format: lengthFormat))
            
            guard data.count >= lengthLength + valueLength else {
                let fieldLength : UInt = (data.count - lengthLength >= 0) ? UInt(data.count - lengthLength) : 0
                throw ISOError.deserializeMessageFailed(reason: .fieldValueIsLessThanDecodedLength(fieldNumber: fieldNumber, decodedLength: UInt(valueLength), actualLength: fieldLength))
            }
            guard valueLength > 0 else {
                let restData = data.count > lengthLength ? data.subdata(in: Range(lengthLength...data.count - 1)) : Data()
                return ("", restData)
            }
            let value = data.subdata(in: Range(lengthLength...lengthLength + valueLength - 1))
            let hexString = value.map { String(format: "%02X", $0) }.joined()
            let restData = data.count > lengthLength + valueLength ? data.subdata(in: Range((lengthLength + valueLength)...data.count - 1)) : Data()
            return (hexString, restData)
            
        case .llnum(let lengthFormat, let padding), .lllnum(let lengthFormat, let padding):
            
            var lengthLength = 0
            var valueLength = 0
            
            switch lengthFormat {
            case .bcd:
                lengthLength = 1
                if case .lllnum(_,_) = format {
                    lengthLength = 2
                }
            case .ascii:
                lengthLength = 2
                if case .lllnum(_,_) = format {
                    lengthLength = 3
                }
            }
            
            guard data.count >= lengthLength else {
                throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeFieldLength(fieldNumber: fieldNumber))
            }
            
            valueLength = try Int(readLength(data: data.subdata(in: Range(0...lengthLength - 1)), format: lengthFormat))
            
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
            
        case .undefined:
            throw ISOError.deserializeMessageFailed(reason: .fieldFormatIsUndefined(fieldNumber: fieldNumber))
        }
    }
}
