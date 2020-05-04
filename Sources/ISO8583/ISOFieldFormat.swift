//
//  ISOFieldFormat.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public enum ISOFieldFormat {
    case alpha(length: UInt)
    case binary(length: UInt)
    case numeric(length: UInt)
    case llvar(lengthFormat: ISONumberFormat)
    case lllvar(lengthFormat: ISONumberFormat)
    case llbin(lengthFormat: ISONumberFormat)
    case lllbin(lengthFormat: ISONumberFormat)
    case llnum(lengthFormat: ISONumberFormat)
    case lllnum(lengthFormat: ISONumberFormat)
    case undefined
}
