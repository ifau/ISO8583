//
//  ISOScheme.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public protocol ISOScheme {
    
    /// - Returns: Number of bytes before message which used to specify the length of a message
    func numberOfBytesForLength() -> UInt
    /// - Returns: Format of message length
    func lengthFormat() -> ISONumberFormat
    /// - Returns: Format of message mti
    func mtiFormat() -> ISONumberFormat
    /// - Returns: Format of specified field
    func fieldFormat(for fieldNumber: UInt) -> ISOFieldFormat
}
