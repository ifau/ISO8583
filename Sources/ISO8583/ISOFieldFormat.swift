//
//  ISOFieldFormat.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public enum ISOFieldFormat {
    
    /// Fixed length alphanumeric value
    case alpha(length: UInt, valueFormat: ISOStringFormat)
    /// Fixed length binary value
    case binary(length: UInt)
    /// Fixed length numeric value
    case numeric(length: UInt)
    /// Variable length alphanumeric value with a 2 digit encoded length
    case llvar(lengthFormat: ISONumberFormat, valueFormat: ISOStringFormat)
    /// Variable length alphanumeric value with a 3 digit encoded length
    case lllvar(lengthFormat: ISONumberFormat, valueFormat: ISOStringFormat)
    /// Variable length binary value with a 2 digit encoded length
    case llbin(lengthFormat: ISONumberFormat)
    /// Variable length binary value with a 3 digit encoded length
    case lllbin(lengthFormat: ISONumberFormat)
    /// Variable length numeric value with a 2 digit encoded length
    case llnum(lengthFormat: ISONumberFormat)
    /// Variable length numeric value with a 3 digit encoded length
    case lllnum(lengthFormat: ISONumberFormat)
    /// Undefined format
    case undefined
}
