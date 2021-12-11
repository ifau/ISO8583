//
//  BitmapEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import Foundation

internal class BitmapEncoder {
    
    static internal func encode(fieldNumbers: [UInt]) throws -> Data {
        
        let incorrectFieldNumbers = fieldNumbers.filter { ($0 < 2) || ($0 > 128) }
        guard incorrectFieldNumbers.count == 0 else {
            throw ISOError.serializeMessageFailed(reason: .messageContainIncorrectFieldNumbers(incorrectFieldNumbers))
        }
        
        let haveSecondaryBitmap = fieldNumbers.contains(where: { $0 > 64 })
        
        // Create ranges 1...8, 9...16, 17...24, 25...32, 33...40, 41...48, 49...56, 57...64
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
    
    static internal func decode(from data: Data) throws -> ([UInt8], Data) {
        
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
}
