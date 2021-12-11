//
//  MTIEncoder.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import Foundation

internal class MTIEncoder {
    
    static internal func encode(_ mti: UInt, format: ISONumberFormat) throws -> Data {
        
        guard mti <= 9999 else {
            throw ISOError.serializeMessageFailed(reason: .messageContainIncorrectMTI(mti))
        }
        
        switch format {
        case .bcd:
            return try LengthEncoder.encode(mti, numberOfBytes: 2, format: .bcd)
        case .ascii:
            return try LengthEncoder.encode(mti, numberOfBytes: 4, format: .ascii)
        }
    }
    
    static internal func decode(from data: Data, format: ISONumberFormat) throws -> (UInt, Data) {
        
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
        
        mti = try LengthEncoder.decode(from: data.subdata(in: Range(0...mtiLength - 1)), format: format)
        restData = mtiLength < data.count ? data.subdata(in: Range(mtiLength...data.count - 1)) : Data()
        return (mti, restData)
    }
}
