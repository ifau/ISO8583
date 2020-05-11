//
//  ISOFieldFormat.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public enum ISOFieldFormat {
    case alpha(length: UInt, valueFormat: ISOStringFormat)
    case binary(length: UInt)
    case numeric(length: UInt)
    case llvar(lengthFormat: ISONumberFormat, valueFormat: ISOStringFormat)
    case lllvar(lengthFormat: ISONumberFormat, valueFormat: ISOStringFormat)
    case llbin(lengthFormat: ISONumberFormat)
    case lllbin(lengthFormat: ISONumberFormat)
    case llnum(lengthFormat: ISONumberFormat)
    case lllnum(lengthFormat: ISONumberFormat)
    case undefined
}
