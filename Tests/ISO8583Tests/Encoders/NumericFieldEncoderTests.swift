//
//  NumericFieldEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import XCTest
@testable import ISO8583

class NumericFieldEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectField", testEncodeCorrectField),
        ("testEncodeFieldWithWrongLength", testEncodeFieldWithWrongLength),
        ("testEncodeFieldWithNotNumericCharacters", testEncodeFieldWithNotNumericCharacters),
        
        ("testDecodeCorrectField", testDecodeCorrectField),
        ("testDecodeFieldWithWrongLength", testDecodeFieldWithWrongLength),
        ("testDecodeFieldWithNotNumericCharacters", testDecodeFieldWithNotNumericCharacters)
    ]
    
    // MARK: - Encode Field Tests
    
    func testEncodeCorrectField() throws {
        
        // Given
        
        let fieldValue = "123000000000000000000"
        let encodedFieldValueWithLeftPadding = Data([0x01, 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let encodedFieldValueWithRightPadding = Data([0x12, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        let fieldLength = UInt(fieldValue.count)
        
        // When
        
        let encodeFieldWithLeftPaddingResult = try? NumericFieldEncoder.encode(value: fieldValue, length: fieldLength, padding: .left)
        let encodeFieldWithRightPaddingResult = try? NumericFieldEncoder.encode(value: fieldValue, length: fieldLength, padding: .right)
        
        // Then
        
        XCTAssertEqual(encodeFieldWithLeftPaddingResult, encodedFieldValueWithLeftPadding)
        XCTAssertEqual(encodeFieldWithRightPaddingResult, encodedFieldValueWithRightPadding)
    }
    
    func testEncodeFieldWithWrongLength() throws {
        
        // Given
        
        let fieldValue = "123000000000000000000"
        let fieldValueWithWrongLength = fieldValue.replacingOccurrences(of: "23", with: "")
        let fieldLength = UInt(fieldValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try NumericFieldEncoder.encode(value: fieldValueWithWrongLength, length: fieldLength, padding: .right)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testEncodeFieldWithNotNumericCharacters() throws {
        
        // Given
        
        let fieldValue = "123000000000000000000"
        let fieldValueWithNotNumericCharacters = fieldValue.replacingOccurrences(of: "23", with: "xy")
        let fieldLength = UInt(fieldValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try NumericFieldEncoder.encode(value: fieldValueWithNotNumericCharacters, length: fieldLength, padding: .right)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Decode Field Tests
    
    func testDecodeCorrectField() throws {
        
        // Given

        let fieldEncodedData = Data([0x01, 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let fieldValueWithLeftPaddingValue  = "123000000000000000000"
        let fieldValueWithRightPaddingValue = "012300000000000000000"
        let fieldLength = UInt(fieldValueWithLeftPaddingValue.count)
        
        // When

        let (decodeFieldWithLeftPaddingResult, _) = try! NumericFieldEncoder.decode(data: fieldEncodedData, length: fieldLength, padding: .left)
        let (decodeFieldWithRightPaddingResult, _) = try! NumericFieldEncoder.decode(data: fieldEncodedData, length: fieldLength, padding: .right)
        
        // Then

        XCTAssertEqual(decodeFieldWithLeftPaddingResult, fieldValueWithLeftPaddingValue)
        XCTAssertEqual(decodeFieldWithRightPaddingResult, fieldValueWithRightPaddingValue)
    }
    
    func testDecodeFieldWithWrongLength() throws {
        
        // Given

        let fieldEncodedData = Data([0x01, 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let fieldValueWithRightPaddingValue = "012300000000000000000"
        let fieldEncodedDataWithWrongLength = fieldEncodedData.subdata(in: Range(0...4))
        let fieldLength = UInt(fieldValueWithRightPaddingValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try NumericFieldEncoder.decode(data: fieldEncodedDataWithWrongLength, length: fieldLength, padding: .right)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testDecodeFieldWithNotNumericCharacters() throws {
        
        // Given

        let fieldEncodedData = Data([0x01, 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let fieldValueWithRightPaddingValue = "012300000000000000000"
        
        var fieldEncodedDataWithNotNumericCharacters = fieldEncodedData
        fieldEncodedDataWithNotNumericCharacters.replaceSubrange(Range(4...5), with: Data([0xCB, 0xAB]))
        
        let fieldLength = UInt(fieldValueWithRightPaddingValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try NumericFieldEncoder.decode(data: fieldEncodedDataWithNotNumericCharacters, length: fieldLength, padding: .right)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
}
