//
//  LengthEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import Foundation

internal class LengthEncoder {
    
    static internal func encode(_ length: UInt, numberOfBytes: UInt, format: ISONumberFormat) throws -> Data {
        
        guard numberOfBytes > 0 else {
            throw ISOError.serializeMessageFailed(reason: .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: 0, actualLength: length))
        }
        
        let asciiString = String(format: "%0\(numberOfBytes)d", length)
        
        switch format {
        case .bcd:
            // Check that length is less or equal to max value (99 for 1 byte, 9999 for 2 bytes, 999999 for 3 bytes, etc.)
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
            // Check that length is less or equal to max value (9 for 1 byte, 99 for two bytes, 999 for three bytes, etc.)
            let maximumLengthFloat = pow(Float(10), Float(numberOfBytes)) - 1
            let maximumLength = maximumLengthFloat < Float(UInt.max) ? UInt(maximumLengthFloat) : UInt.max
            guard length <= maximumLength else {
                throw ISOError.serializeMessageFailed(reason: .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: maximumLength, actualLength: length))
            }
            guard let result = asciiString.data(using: .ascii) else {
                // Should never happen
                throw ISOError.serializeMessageFailed(reason: .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: maximumLength, actualLength: length))
            }
            return result
        }
    }
    
    static internal func decode(from data: Data, format: ISONumberFormat) throws -> UInt {
        
        switch format {
        case .bcd:
            var value : UInt = 0
            var power : UInt = 1
            for (_, byteValue) in data.enumerated().reversed() {
                // Check that byte contains only numbers 0 1 2 3 4 5 6 7 8 9, without a b c d e f
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
}
