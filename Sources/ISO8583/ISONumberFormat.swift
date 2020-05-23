//
//  ISONumberFormat.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import Foundation

public enum ISONumberFormat {
    
    /// Packed BCD format. Every byte contains representation of two digits (e.g. encoded value of `12` is `[0x12]`)
    case bcd
    /// ASCII format. Every byte contains ASCII value of one digit (e.g. encoded value of `12` is `[0x31, 0x32]`)
    case ascii
}
