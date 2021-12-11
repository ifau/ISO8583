//
//  BinaryFieldEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import XCTest
@testable import ISO8583

class BinaryFieldEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectField", testEncodeCorrectField),
        ("testEncodeFieldWithWrongLength", testEncodeFieldWithWrongLength),
        ("testEncodeFieldWithNotHexCharacters", testEncodeFieldWithNotHexCharacters),
        
        ("testDecodeCorrectField", testDecodeCorrectField),
        ("testDecodeFieldWithWrongLength", testDecodeFieldWithWrongLength)
    ]
    
    // MARK: - Encode Field Tests
    
    func testEncodeCorrectField() throws {
        
        // Given
        
        let fieldValue = "00112233445566778899aabbccddeeff"
        let encodedFieldValue = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        let fieldLength = UInt(encodedFieldValue.count)
        
        // When
        
        let encodeFieldResult = try? BinaryFieldEncoder.encode(value: fieldValue, length: fieldLength)
        
        // Then
        
        XCTAssertEqual(encodeFieldResult, encodedFieldValue)
    }
    
    func testEncodeFieldWithWrongLength() throws {
        
        // Given
        
        let fieldValueWithWrongLength = "00112233445566778899aabbccddeeff".replacingOccurrences(of: "ff", with: "")
        let encodedFieldValue = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        let fieldLength = UInt(encodedFieldValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try BinaryFieldEncoder.encode(value: fieldValueWithWrongLength, length: fieldLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testEncodeFieldWithNotHexCharacters() throws {
        
        // Given
        
        let fieldValueWithNotHexCharacters = "00112233445566778899aabbccddeeff".replacingOccurrences(of: "ff", with: "xy")
        let encodedFieldValue = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        let fieldLength = UInt(encodedFieldValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try BinaryFieldEncoder.encode(value: fieldValueWithNotHexCharacters, length: fieldLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Decode Field Tests
    
    func testDecodeCorrectField() throws {
        
        // Given
        
        let fieldValue = "00112233445566778899aabbccddeeff"
        let encodedFieldValue = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        let fieldLength = UInt(encodedFieldValue.count)
        
        // When
        
        let (decodeFieldResult, _) = try! BinaryFieldEncoder.decode(data: encodedFieldValue, length: fieldLength)
        
        // Then
        
        XCTAssertEqual(decodeFieldResult.lowercased(), fieldValue)
    }
    
    func testDecodeFieldWithWrongLength() throws {
        
        // Given
        
        let encodedFieldValue = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        let encodedFieldValueWithWrongLength = encodedFieldValue.subdata(in: Range(0...8))
        let fieldLength = UInt(encodedFieldValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try BinaryFieldEncoder.decode(data: encodedFieldValueWithWrongLength, length: fieldLength)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
    }
}
