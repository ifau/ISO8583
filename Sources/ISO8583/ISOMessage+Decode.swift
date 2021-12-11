//
//  ISOMessage+Decode.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import Foundation

extension ISOMessage {
    
    internal func decode(data: Data, using scheme: ISOScheme) throws -> ISOMessage {
        
        let message = ISOMessage()
        var tempData = Data()
        
        let numberOfBytesForLength = scheme.numberOfBytesForLength()
        
        if numberOfBytesForLength > 0 {
            
            guard data.count > numberOfBytesForLength else {
                throw ISOError.deserializeMessageFailed(reason: .notEnoughDataForDecodeMessageLength)
            }
            
            let messageLength = try LengthEncoder.decode(from: data.subdata(in: Range(0...Int(numberOfBytesForLength - 1))), format: scheme.lengthFormat())
            
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
        
        let (mti, restDataAfterReadMTI) = try MTIEncoder.decode(from: tempData, format: scheme.mtiFormat())
        tempData = restDataAfterReadMTI
        message.mti = mti
        
        let (bitmap, restDataAfterReadBitmap) = try BitmapEncoder.decode(from: tempData)
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
    
    private func readField(fieldNumber: UInt, data: Data, format: ISOFieldFormat) throws -> (String, Data) {
        
        switch format {
        case .alpha(let length, let valueFormat):
            return try AlphaFieldEncoder.decode(data: data, length: length, format: valueFormat, fieldNumber: fieldNumber)
            
        case .binary(let length):
            return try BinaryFieldEncoder.decode(data: data, length: length, fieldNumber: fieldNumber)
        
        case .numeric(let length, let padding):
            
            return try NumericFieldEncoder.decode(data: data, length: length, padding: padding, fieldNumber: fieldNumber)
            
        case .llvar(let lengthFormat, let valueFormat), .lllvar(let lengthFormat, let valueFormat):
            
            var numberOfBytesForLength: UInt = 0
            
            switch lengthFormat {
            case .bcd:
                numberOfBytesForLength = 1
                if case .lllvar(_, _) = format {
                    numberOfBytesForLength = 2
                }
            case .ascii:
                numberOfBytesForLength = 2
                if case .lllvar(_, _) = format {
                    numberOfBytesForLength = 3
                }
            }
            
            return try VariableAlphaFieldEncoder.decode(data: data, numberOfBytesForLength: numberOfBytesForLength, lengthFormat: lengthFormat, valueFormat: valueFormat, fieldNumber: fieldNumber)
            
        case .llbin(let lengthFormat), .lllbin(let lengthFormat):
            
            var numberOfBytesForLength: UInt = 0
            
            switch lengthFormat {
            case .bcd:
                numberOfBytesForLength = 1
                if case .lllbin(_) = format {
                    numberOfBytesForLength = 2
                }
            case .ascii:
                numberOfBytesForLength = 2
                if case .lllbin(_) = format {
                    numberOfBytesForLength = 3
                }
            }
            
            return try VariableBinaryFieldEncoder.decode(data: data, numberOfBytesForLength: numberOfBytesForLength, lengthFormat: lengthFormat, fieldNumber: fieldNumber)
            
        case .llnum(let lengthFormat, let padding), .lllnum(let lengthFormat, let padding):
            
            var numberOfBytesForLength: UInt = 0
            
            switch lengthFormat {
            case .bcd:
                numberOfBytesForLength = 1
                if case .lllnum(_,_) = format {
                    numberOfBytesForLength = 2
                }
            case .ascii:
                numberOfBytesForLength = 2
                if case .lllnum(_,_) = format {
                    numberOfBytesForLength = 3
                }
            }
            
            return try VariableNumericFieldEncoder.decode(data: data, numberOfBytesForLength: numberOfBytesForLength, lengthFormat: lengthFormat, padding: padding, fieldNumber: fieldNumber)
            
        case .undefined:
            throw ISOError.deserializeMessageFailed(reason: .fieldFormatIsUndefined(fieldNumber: fieldNumber))
        }
    }
}
