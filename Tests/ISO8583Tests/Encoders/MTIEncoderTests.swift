//
//  MTIEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import XCTest
@testable import ISO8583

class MTIEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectMTI", testEncodeCorrectMTI),
        ("testEncodeIncorrectMTI", testEncodeIncorrectMTI),
        
        ("testDecodeCorrectMTI", testDecodeCorrectMTI),
        ("testDecodeIncorrectMTI", testDecodeIncorrectMTI)
    ]
    
    // MARK: - Encode Tests
    
    func testEncodeCorrectMTI() {
        
        // Given
        
        let value : UInt = 800
        let bcdEncodedValue = Data([0x08, 0x00])
        let asciiEncodedValue = "0800".data(using: .ascii)!
        
        // When
        
        let asciiEncodedResult = try? MTIEncoder.encode(value, format: .ascii)
        let bcdEncodedResult = try? MTIEncoder.encode(value, format: .bcd)
        
        // Then
        
        XCTAssertEqual(asciiEncodedResult, asciiEncodedValue)
        XCTAssertEqual(bcdEncodedResult, bcdEncodedValue)
    }
    
    func testEncodeIncorrectMTI() {
        
        // Given
        
        let incorrectValue : UInt = 10_000
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try MTIEncoder.encode(incorrectValue, format: .ascii)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.messageContainIncorrectMTI(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try MTIEncoder.encode(incorrectValue, format: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.messageContainIncorrectMTI(_) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Encode Tests
    
    func testDecodeCorrectMTI() {
        
        // Given
        
        let bcdEncodedData = Data([0x08, 0x00])
        let asciiEncodedData = "0800".data(using: .ascii)!
        let value : UInt = 800
        
        // When
        
        let (bcdDecodedResult, _) = try! MTIEncoder.decode(from: bcdEncodedData, format: .bcd)
        let (asciiDecodedResult, _) = try! MTIEncoder.decode(from: asciiEncodedData, format: .ascii)
        
        // Then
        
        XCTAssertEqual(bcdDecodedResult, value)
        XCTAssertEqual(asciiDecodedResult, value)
    }
    
    func testDecodeIncorrectMTI() {
        
        // Given
        
        let incorrectBCDEncodedData = Data([0x08])
        let incorrectASCIIEncodedData = "08".data(using: .ascii)!
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try MTIEncoder.decode(from: incorrectBCDEncodedData, format: .bcd)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeMTI = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try MTIEncoder.decode(from: incorrectASCIIEncodedData, format: .ascii)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeMTI = reason else { return XCTFail() }
        }
    }
}
