//
//  ISOMessageSerializer.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public final class ISOMessageSerializer {
    
    public init() {
        
    }
    
    /// Serialize `ISOMessage` object into binary message according to provided scheme
    /// - Parameters:
    ///   - message: `ISOMessage` object for serialization
    ///   - scheme: `ISOScheme` which describe protocol that will be used for serialize message
    /// - Throws: `ISOError.serializeMessageFailed(reason)`, see reason for details
    /// - Returns: Data of serialized message
    public func serialize(message: ISOMessage, scheme: ISOScheme) throws -> Data {
        
        var result = Data()
        var tempData = Data()
        
        let mti = try serializeMTI(message.mti, format: scheme.mtiFormat())
        tempData.append(mti)
        
        let bitmap = try serializeBitmap(fieldNumbers: message.fields.keys.sorted())
        tempData.append(bitmap)
        
        for fieldNumber in message.fields.keys.sorted() {
            let value = message.fields[fieldNumber] ?? ""
            let field = try serializeField(fieldNumber: fieldNumber, value: value, format: scheme.fieldFormat(for: fieldNumber))
            tempData.append(field)
        }
        
        if scheme.numberOfBytesForLength() > 0 {
            let messageLength = try serializeLength(UInt(tempData.count), numberOfBytes: scheme.numberOfBytesForLength(), format: scheme.lengthFormat())
            result.append(messageLength)
        }
        
        result.append(tempData)
        
        return result
    }
    
    internal func serializeLength(_ length: UInt, numberOfBytes: UInt, format: ISONumberFormat) throws -> Data {
        
        guard numberOfBytes > 0 else {
            throw ISOError.serializeMessageFailed(reason: .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: 0, actualLength: length))
        }
        
        let asciiString = String(format: "%0\(numberOfBytes)d", length)
        
        switch format {
        case .bcd:
            /// Check length is less or equal to max value (99 for 1 byte, 9999 for 2 bytes, 999999 for 3 bytes, etc.)
            let maximumLengthFloat = pow(Float(10), Float(2*numberOfBytes)) - 1
            let maximumLength = maximumLengthFloat < Float(UInt.max) ? UInt(maximumLengthFloat) : UInt.max
            guard length <= maximumLength else {
                throw ISOError.serializeMessageFailed(reason: .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: maximumLength, actualLength: length))
            }
            var result : [UInt8] = []
            let asciiBytesOfLengthString = asciiString.compactMap { $0.asciiValue }
            var asciiBytePosition = 0
            
            if asciiBytesOfLengthString.count % 2 == 1 {
                result.append(asciiBytesOfLengthString[0] - 48)
                asciiBytePosition = 1
            }
            
            while (asciiBytePosition < asciiBytesOfLengthString.count) {
                let hight = (asciiBytesOfLengthString[asciiBytePosition] - 48) << 4
                let low = asciiBytesOfLengthString[asciiBytePosition + 1] - 48
                result.append((hight | low))
                asciiBytePosition += 2
            }
            
            while result.count < numberOfBytes {
                result.insert(0x00, at: 0)
            }
            return Data(result)
            
        case .ascii:
            /// Check length is less or equal to max value (9 for 1 byte, 99 for two bytes, 999 for three bytes, etc.)
            let maximumLengthFloat = pow(Float(10), Float(numberOfBytes)) - 1
            let maximumLength = maximumLengthFloat < Float(UInt.max) ? UInt(maximumLengthFloat) : UInt.max
            guard length <= maximumLength else {
                throw ISOError.serializeMessageFailed(reason: .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: maximumLength, actualLength: length))
            }
            guard let result = asciiString.data(using: .ascii) else {
                /// Should never happen
                throw ISOError.serializeMessageFailed(reason: .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: maximumLength, actualLength: length))
            }
            return result
        }
    }
    
    internal func serializeMTI(_ mti: UInt, format: ISONumberFormat) throws -> Data {
        
        guard mti <= 9999 else {
            throw ISOError.serializeMessageFailed(reason: .messageContainIncorrectMTI(mti))
        }
        
        switch format {
        case .bcd:
            return try serializeLength(mti, numberOfBytes: 2, format: .bcd)
        case .ascii:
            return try serializeLength(mti, numberOfBytes: 4, format: .ascii)
        }
    }
    
    internal func serializeBitmap(fieldNumbers: [UInt]) throws -> Data {
        
        let incorrectFieldNumbers = fieldNumbers.filter { ($0 < 2) || ($0 > 128) }
        guard incorrectFieldNumbers.count == 0 else {
            throw ISOError.serializeMessageFailed(reason: .messageContainIncorrectFieldNumbers(incorrectFieldNumbers))
        }
        
        let haveSecondaryBitmap = fieldNumbers.contains(where: { $0 > 64 })
        
        /// Create ranges 1...8, 9...16, 17...24, 25...32, 33...40, 41...48, 49...56, 57...64
        let bitRanges = (1...(haveSecondaryBitmap ? 16 : 8)).map { (8*$0 - 7)...(8*$0) }

        var bitMap = bitRanges.map { bitRange -> UInt8 in

            var byte : UInt8 = 0
            for (index, value) in bitRange.enumerated() {
                guard fieldNumbers.contains(where: { $0 == value }) else { continue }
                byte |= (0b10000000 >> index)
            }
            return byte
        }
        
        if haveSecondaryBitmap {
            bitMap[0] = bitMap[0] | 0b10000000
        }
        
        return Data(bytes: bitMap, count: bitMap.count)
    }
    
    internal func serializeField(fieldNumber: UInt = 0, value: String, format: ISOFieldFormat) throws -> Data {
        
        switch format {
        case .alpha(let length, let valueFormat):
            guard value.count == length else {
                throw ISOError.serializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(value.count)))
            }
            guard value.isConfirmToFormat(valueFormat) else {
                throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: valueFormat, actualValue: value))
            }
            guard let result = value.data(using: .ascii) else {
                throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber:fieldNumber, declaredFormat: valueFormat, actualValue: value))
            }
            return result
        case .binary(let length):

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
        
        case .numeric(let length):
            guard value.count == length else {
                throw ISOError.serializeMessageFailed(reason: .fieldLengthIsNotEqualToDeclaredLength(fieldNumber: fieldNumber, declaredLength: length, actualLength: UInt(value.count)))
            }
            guard value.isConfirmToFormat(.n), let numericValue = UInt(value) else {
                throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: .n, actualValue: value))
            }
            
            let numberOfBytes : UInt = (length % 2 == 1) ? ((length + 1) / 2) : (length / 2)
            let result = try serializeLength(numericValue, numberOfBytes: numberOfBytes, format: .bcd)
            return result
            
        case .llvar(let lengthFormat, let valueFormat), .lllvar(let lengthFormat, let valueFormat):
            
            var result = Data()
            var numberOfBytesForLength : UInt = 0
            var maximumNumberOfBytesForValue = 0
            
            switch lengthFormat {
            case .bcd:
                numberOfBytesForLength = 1
                if case .lllvar(_) = format {
                    numberOfBytesForLength = 2
                }
                /// 99 for 1 byte, 9999 for 2 bytes
                maximumNumberOfBytesForValue = Int(pow(Double(10), Double(2*numberOfBytesForLength))) - 1
            case .ascii:
                numberOfBytesForLength = 2
                if case .lllvar(_) = format {
                    numberOfBytesForLength = 3
                }
                /// 99 for 2 bytes, 999 for 3 bytes
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
            
            let encodedLength = try serializeLength(UInt(encodedValue.count), numberOfBytes: numberOfBytesForLength, format: lengthFormat)
            result.append(encodedLength)
            result.append(encodedValue)
            return result
            
        case .llbin(let lengthFormat), .lllbin(let lengthFormat):

            var result = Data()
            var numberOfBytesForLength : UInt = 0
            var maximumNumberOfBytesForValue = 0
            
            switch lengthFormat {
            case .bcd:
                numberOfBytesForLength = 1
                if case .lllbin(_) = format {
                    numberOfBytesForLength = 2
                }
                /// 99 for 1 byte, 9999 for 2 bytes
                maximumNumberOfBytesForValue = Int(pow(Double(10), Double(2*numberOfBytesForLength))) - 1
            case .ascii:
                numberOfBytesForLength = 2
                if case .lllbin(_) = format {
                    numberOfBytesForLength = 3
                }
                /// 99 for 2 bytes, 999 for 3 bytes
                maximumNumberOfBytesForValue = Int(pow(Double(10), Double(numberOfBytesForLength))) - 1
            }
            
            guard value.count % 2 == 0, value.isConfirmToFormat(.hex) else {
                throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: .hex, actualValue: value))
            }
            
            let chars = Array(value)
            let encodedValue: [UInt8] = stride(from: 0, to: chars.count, by: 2)
                .map { UInt8(String([chars[$0], chars[$0+1]]), radix: 16) }
                .compactMap{ $0 }
            
            guard encodedValue.count <= maximumNumberOfBytesForValue else {
                throw ISOError.serializeMessageFailed(reason: .fieldValueIsMoreThanMaximumLengthForDeclaredFormat(fieldNumber: fieldNumber, maximumLength: UInt(maximumNumberOfBytesForValue), actualLength: UInt(encodedValue.count)))
            }
            
            let encodedLength = try serializeLength(UInt(encodedValue.count), numberOfBytes: numberOfBytesForLength, format: lengthFormat)
            result.append(encodedLength)
            result.append(Data(encodedValue))
            return result
            
        case .llnum(let lengthFormat), .lllnum(let lengthFormat):
            
            var result = Data()
            var numberOfBytesForLength : UInt = 0
            var maximumNumberOfBytesForValue = 0
            
            switch lengthFormat {
            case .bcd:
                numberOfBytesForLength = 1
                if case .lllnum(_) = format {
                    numberOfBytesForLength = 2
                }
                /// 99 for 1 byte, 9999 for 2 bytes
                maximumNumberOfBytesForValue = Int(pow(Double(10), Double(2*numberOfBytesForLength))) - 1
            case .ascii:
                numberOfBytesForLength = 2
                if case .lllnum(_) = format {
                    numberOfBytesForLength = 3
                }
                /// 99 for 2 bytes, 999 for 3 bytes
                maximumNumberOfBytesForValue = Int(pow(Double(10), Double(numberOfBytesForLength))) - 1
            }
            
            guard value.isConfirmToFormat(.n) else {
                throw ISOError.serializeMessageFailed(reason: .fieldValueIsNotConformToDeclaredFormat(fieldNumber: fieldNumber, declaredFormat: .n, actualValue: value))
            }
            
            var chars = Array(value)
            if chars.count % 2 == 1 {
                chars.insert("0", at: 0)
            }
            
            let numberOfBytesForValue = chars.count / 2
            guard numberOfBytesForValue <= maximumNumberOfBytesForValue else {
                throw ISOError.serializeMessageFailed(reason: .fieldValueIsMoreThanMaximumLengthForDeclaredFormat(fieldNumber: fieldNumber, maximumLength: UInt(maximumNumberOfBytesForValue), actualLength: UInt(numberOfBytesForValue)))
            }
            
            let encodedValue: [UInt8] = stride(from: 0, to: chars.count, by: 2)
                .map { UInt8(String([chars[$0], chars[$0+1]]), radix: 16) }
                .compactMap{ $0 }
            
            let encodedLength = try serializeLength(UInt(value.count), numberOfBytes: numberOfBytesForLength, format: lengthFormat)
            result.append(encodedLength)
            result.append(Data(encodedValue))
            return result
            
        case .undefined:
            throw ISOError.serializeMessageFailed(reason: .fieldFormatIsUndefined(fieldNumber: fieldNumber))
        }
    }
}
