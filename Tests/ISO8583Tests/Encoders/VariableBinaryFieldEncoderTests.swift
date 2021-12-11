//
//  VariableBinaryFieldEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import XCTest
@testable import ISO8583

class VariableBinaryFieldEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectLLBINField", testEncodeCorrectLLBINField),
        ("testEncodeCorrectLLLBINField", testEncodeCorrectLLLBINField),
        ("testEncodeIncorrectLLBINField", testEncodeIncorrectLLBINField),
        ("testEncodeIncorrectLLLBINField", testEncodeIncorrectLLLBINField),
        
        ("testDecodeCorrectLLBINField", testDecodeCorrectLLBINField),
        ("testDecodeCorrectLLLBINField", testDecodeCorrectLLLBINField),
        ("testDecodeIncorrectLLBINField", testDecodeIncorrectLLBINField),
        ("testDecodeIncorrectLLLBINField", testDecodeIncorrectLLLBINField)
    ]
    
    // MARK: - Encode Field Tests
    
    func testEncodeCorrectLLBINField() throws {
        
        // Given
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x16]
        let asciiLength : [UInt8] = Array("16".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        // When

        let encodeDataWithBCDEncodedLengthResult = try? VariableBinaryFieldEncoder.encode(value: value, numberOfBytesForLength: 1, lengthFormat: .bcd)
        let encodeDataWithASCIIEncodedLengthResult = try? VariableBinaryFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .ascii)

        // Then

        XCTAssertEqual(encodeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
    }
    
    func testEncodeIncorrectLLBINField() throws {
        
        // Given
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueWithNotHexCharacters = value.replacingOccurrences(of: "FF", with: "XY")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "FF", count: 100)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "FF", count: 100)

        // When

        // Then

        XCTAssertThrowsError(try VariableBinaryFieldEncoder.encode(value: valueWithNotHexCharacters, numberOfBytesForLength: 1, lengthFormat: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.encode(value: valueMoreThanMaxBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.encode(value: valueMoreThanMaxASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testEncodeCorrectLLLBINField() throws {
        
        // Given
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x00, 0x16]
        let asciiLength : [UInt8] = Array("016".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        // When

        let encodeDataWithBCDEncodedLengthResult = try VariableBinaryFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .bcd)
        let encodeDataWithASCIIEncodedLengthResult = try VariableBinaryFieldEncoder.encode(value: value, numberOfBytesForLength: 3, lengthFormat: .ascii)

        // Then

        XCTAssertEqual(encodeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
    }
    
    func testEncodeIncorrectLLLBINField() throws {
        
        // Given
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueWithNotHexCharacters = value.replacingOccurrences(of: "FF", with: "XY")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "FF", count: 10_000)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "FF", count: 1_000)

        // When

        // Then

        XCTAssertThrowsError(try VariableBinaryFieldEncoder.encode(value: valueWithNotHexCharacters, numberOfBytesForLength: 2, lengthFormat: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.encode(value: valueMoreThanMaxBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.encode(value: valueMoreThanMaxASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Decode Field Tests
    
    func testDecodeCorrectLLBINField() throws {
        
        // Given
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x16]
        let asciiLength : [UInt8] = Array("16".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        // When
        
        let (decodeDataWithBCDEncodedLengthResult, _) = try VariableBinaryFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd)
        let (decodeDataWithASCIIEncodedLengthResult, _) = try VariableBinaryFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii)
        
        // Then
        
        XCTAssertEqual(decodeDataWithBCDEncodedLengthResult.uppercased(), value.uppercased())
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthResult.uppercased(), value.uppercased())
    }
    
    func testDecodeIncorrectLLBINField() throws {
        
        // Given
        
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x16]
        let asciiLength : [UInt8] = Array("16".utf8)
        
        let dataWithNotEnougthBytesForBCDLength = Data()
        let dataWithNotEnougthBytesForASCIILength = "1".data(using: .ascii)!
        let dataWithLessBytesForValueThanBCDEncodedLength = Data([bcdLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithLessBytesForValueThanASCIIEncodedLength = Data([asciiLength, Array(valueData[0...4])].flatMap { $0 })
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithNotEnougthBytesForBCDLength, numberOfBytesForLength: 1, lengthFormat: .bcd)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithNotEnougthBytesForASCIILength, numberOfBytesForLength: 2, lengthFormat: .ascii)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithLessBytesForValueThanBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithLessBytesForValueThanASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testDecodeCorrectLLLBINField() throws {
        
        // Given
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x00, 0x16]
        let asciiLength : [UInt8] = Array("016".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        // When
        
        let (decodeDataWithBCDEncodedLengthResult, _) = try VariableBinaryFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd)
        let (decodeDataWithASCIIEncodedLengthResult, _) = try VariableBinaryFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii)
        
        // Then
        
        XCTAssertEqual(decodeDataWithBCDEncodedLengthResult.uppercased(), value.uppercased())
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthResult.uppercased(), value.uppercased())
    }
    
    func testDecodeIncorrectLLLBINField() throws {
        
        // Given
        
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x00, 0x16]
        let asciiLength : [UInt8] = Array("016".utf8)
        
        let dataWithNotEnougthBytesForBCDLength = Data([0x00])
        let dataWithNotEnougthBytesForASCIILength = "01".data(using: .ascii)!
        let dataWithLessBytesForValueThanBCDEncodedLength = Data([bcdLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithLessBytesForValueThanASCIIEncodedLength = Data([asciiLength, Array(valueData[0...4])].flatMap { $0 })
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithNotEnougthBytesForBCDLength, numberOfBytesForLength: 2, lengthFormat: .bcd)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithNotEnougthBytesForASCIILength, numberOfBytesForLength: 3, lengthFormat: .ascii)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithLessBytesForValueThanBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableBinaryFieldEncoder.decode(data: dataWithLessBytesForValueThanASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
    }
}
