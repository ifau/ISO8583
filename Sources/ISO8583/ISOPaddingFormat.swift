//
//  ISOPaddingFormat.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/12/2020.
//

import Foundation

public enum ISOPaddingFormat {
    
    /// Left padding (e.g. left padded value of `123` is `[0x01, 0x12]`)
    case left
    /// Right padding (e.g. right padded value of `123` is `[0x12, 0x30]`)
    case right
}
