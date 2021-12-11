//
//  LengthEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import XCTest
@testable import ISO8583

class LengthEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectASCIILength", testEncodeCorrectASCIILength),
        ("testEncodeIncorrectASCIILength", testEncodeIncorrectASCIILength),
        ("testEncodeCorrectBCDLength", testEncodeCorrectBCDLength),
        ("testEncodeIncorrectBCDLength", testEncodeIncorrectBCDLength),
        
        ("testDecodeCorrectASCIILength", testDecodeCorrectASCIILength),
        ("testDecodeIncorrectASCIILength", testDecodeIncorrectASCIILength),
        ("testDecodeCorrectBCDLength", testDecodeCorrectBCDLength),
        ("testDecodeIncorrectBCDLength", testDecodeIncorrectBCDLength)
    ]
    
    // MARK: - Encode Tests
    
    func testEncodeCorrectASCIILength() throws {
        
        // Given
        
        let length : UInt = 256
        let threeBytesASCIILength = "256".data(using: .ascii)!
        let tenBytesASCIILength = "0000000256".data(using: .ascii)!
        
        // When
        
        let ecodeThreeBytesASCIILengthResult = try? LengthEncoder.encode(length, numberOfBytes: 3, format: .ascii)
        let encodeTenBytesASCIILengthResult = try? LengthEncoder.encode(length, numberOfBytes: 10, format: .ascii)
        
        // Then
        
        XCTAssertEqual(ecodeThreeBytesASCIILengthResult, threeBytesASCIILength)
        XCTAssertEqual(encodeTenBytesASCIILengthResult, tenBytesASCIILength)
    }
    
    func testEncodeIncorrectASCIILength() throws {
        
        XCTAssertThrowsError(try LengthEncoder.encode(1_000, numberOfBytes: 3, format: .ascii)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.lengthIsMoreThanMaximumLengthForDeclaredFormat(_, _) = reason else { return XCTFail() }
        }
    }
    
    func testEncodeCorrectBCDLength() throws {
        
        // Given
        
        let length : UInt = 256
        let threeBytesBCDLength = Data([0x00, 0x02, 0x56])
        let tenBytesBCDLength = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x56])
        
        // When
        
        let ecodeThreeBytesBCDLengthResult = try? LengthEncoder.encode(length, numberOfBytes: 3, format: .bcd)
        let encodeTenBytesBCDLengthResult = try? LengthEncoder.encode(length, numberOfBytes: 10, format: .bcd)
        
        // Then
        
        XCTAssertEqual(ecodeThreeBytesBCDLengthResult, threeBytesBCDLength)
        XCTAssertEqual(encodeTenBytesBCDLengthResult, tenBytesBCDLength)
    }
    
    func testEncodeIncorrectBCDLength() throws {
        
        XCTAssertThrowsError(try LengthEncoder.encode(1_000_000, numberOfBytes: 3, format: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.lengthIsMoreThanMaximumLengthForDeclaredFormat(_, _) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Decode Tests
    
    func testDecodeCorrectASCIILength() throws {
        
        let value : UInt = 154402
        let asciiEncodedData = "154402".data(using: .ascii)!
        
        // When
        
        let decodedResult = try? LengthEncoder.decode(from: asciiEncodedData, format: .ascii)
        
        // Then
        
        XCTAssertEqual(decodedResult, value)
    }
    
    func testDecodeIncorrectASCIILength() throws {
        
        // Given
        
        let incorrectASCIIEncodedData = "15c402".data(using: .ascii)!
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try LengthEncoder.decode(from: incorrectASCIIEncodedData, format: .ascii)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.lengthIsNotConformToDeclaredFormat(_, _) = reason else { return XCTFail() }
        }
    }
    
    func testDecodeCorrectBCDLength() throws {
        
        let value : UInt = 154402
        let bcdEncodedData = Data([0x15, 0x44, 0x02])
        
        // When
        
        let decodedResult = try? LengthEncoder.decode(from: bcdEncodedData, format: .bcd)
        
        // Then
        
        XCTAssertEqual(decodedResult, value)
    }
    
    func testDecodeIncorrectBCDLength() throws {
        
        // Given
        
        let incorrectBCDEncodedData = Data([0x15, 0xc4, 0x02])
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try LengthEncoder.decode(from: incorrectBCDEncodedData, format: .bcd)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.lengthIsNotConformToDeclaredFormat(_, _) = reason else { return XCTFail() }
        }
    }
}
