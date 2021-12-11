//
//  ISOMessage+Encode.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import Foundation

extension ISOMessage {
    
    internal func encode(using scheme: ISOScheme) throws -> Data {
        
        var result = Data()
        var tempData = Data()
        
        let mti = try MTIEncoder.encode(mti, format: scheme.mtiFormat())
        tempData.append(mti)
        
        let bitmap = try BitmapEncoder.encode(fieldNumbers: fields.keys.sorted())
        tempData.append(bitmap)
        
        for fieldNumber in fields.keys.sorted() {
            let value = fields[fieldNumber] ?? ""
            let field = try serializeField(fieldNumber: fieldNumber, value: value, format: scheme.fieldFormat(for: fieldNumber))
            tempData.append(field)
        }
        
        if scheme.numberOfBytesForLength() > 0 {
            let messageLength = try LengthEncoder.encode(UInt(tempData.count), numberOfBytes: scheme.numberOfBytesForLength(), format: scheme.lengthFormat())
            result.append(messageLength)
        }
        
        result.append(tempData)
        
        return result
    }
    
    private func serializeField(fieldNumber: UInt, value: String, format: ISOFieldFormat) throws -> Data {
        
        switch format {
        case .alpha(let length, let valueFormat):
            return try AlphaFieldEncoder.encode(value: value, length: length, format: valueFormat, fieldNumber: fieldNumber)
            
        case .binary(let length):
            return try BinaryFieldEncoder.encode(value: value, length: length, fieldNumber: fieldNumber)
            
        case .numeric(let length, let padding):
            return try NumericFieldEncoder.encode(value: value, length: length, padding: padding, fieldNumber: fieldNumber)
            
        case .llvar(let lengthFormat, let valueFormat), .lllvar(let lengthFormat, let valueFormat):
            
            var numberOfBytesForLength : UInt = 0
            
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
            
            return try VariableAlphaFieldEncoder.encode(value: value, numberOfBytesForLength: numberOfBytesForLength, lengthFormat: lengthFormat, valueFormat: valueFormat, fieldNumber: fieldNumber)
            
        case .llbin(let lengthFormat), .lllbin(let lengthFormat):

            var numberOfBytesForLength : UInt = 0
            
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
            
            return try VariableBinaryFieldEncoder.encode(value: value, numberOfBytesForLength: numberOfBytesForLength, lengthFormat: lengthFormat, fieldNumber: fieldNumber)
            
        case .llnum(let lengthFormat, let padding), .lllnum(let lengthFormat, let padding):
            
            var numberOfBytesForLength : UInt = 0
            
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
            
            return try VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: numberOfBytesForLength, lengthFormat: lengthFormat, padding: padding, fieldNumber: fieldNumber)
            
        case .undefined:
            throw ISOError.serializeMessageFailed(reason: .fieldFormatIsUndefined(fieldNumber: fieldNumber))
        }
    }
}
