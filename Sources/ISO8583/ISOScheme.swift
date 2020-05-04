//
//  ISOScheme.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public protocol ISOScheme {
    func numberOfBytesForLength() -> UInt
    func lengthFormat() -> ISONumberFormat
    func mtiFormat() -> ISONumberFormat
    func fieldFormat(for fieldNumber: UInt) -> ISOFieldFormat
}
