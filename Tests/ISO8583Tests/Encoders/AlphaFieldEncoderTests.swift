//
//  AlphaFieldEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 04/12/2021.
//

import XCTest
@testable import ISO8583

class AlphaFieldEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectField", testEncodeCorrectField),
        ("testEncodeFieldWithWrongLength", testEncodeFieldWithWrongLength),
        ("testEncodeFieldWithWrongFormat", testEncodeFieldWithWrongFormat),
        
        ("testDecodeCorrectField", testDecodeCorrectField),
        ("testDecodeFieldWithWrongLength", testDecodeFieldWithWrongLength),
        ("testDecodeFieldWithWrongFormat", testDecodeFieldWithWrongFormat)
    ]
    
    // MARK: - Encode Field Tests
    
    func testEncodeCorrectField() throws {
        
        // Given
        
        let fieldValue = "alphazxc"
        let encodedFieldValue = fieldValue.data(using: .ascii)!
        let fieldLength = UInt(encodedFieldValue.count)
        let fieldFormat = ISOStringFormat.a
        
        // When
        
        let encodeFieldResult = try? AlphaFieldEncoder.encode(value: fieldValue, length: fieldLength, format: fieldFormat)
        
        // Then
        
        XCTAssertEqual(encodeFieldResult, encodedFieldValue)
    }
    
    func testEncodeFieldWithWrongLength() throws {
        
        // Given
        
        let fieldValue = "alphazxc"
        let fieldValueWithWrongLength = String(fieldValue[..<String.Index(utf16Offset: 4, in: fieldValue)])
        let encodedFieldValue = fieldValue.data(using: .ascii)!
        let fieldLength = UInt(encodedFieldValue.count)
        let fieldFormat = ISOStringFormat.a
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try AlphaFieldEncoder.encode(value: fieldValueWithWrongLength, length: fieldLength, format: fieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testEncodeFieldWithWrongFormat() throws {
        
        // Given
        
        let aValue = "alphazxc"
        let anValue = "alpha123"
        let ansValue = "alpha12$"
        let anValueWithControlCharacter = "alpha12\u{1D}"
        
        let aFieldFormat: ISOStringFormat = [.a]
        let anFieldFormat: ISOStringFormat = [.a, .n]
        let ansFieldFormat: ISOStringFormat = [.a, .n, .s]
        
        let fieldLength = UInt(aValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try AlphaFieldEncoder.encode(value: anValue, length: fieldLength, format: aFieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try AlphaFieldEncoder.encode(value: ansValue, length: fieldLength, format: anFieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try AlphaFieldEncoder.encode(value: anValueWithControlCharacter, length: fieldLength, format: ansFieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Decode Field Tests
    
    func testDecodeCorrectField() throws {
        
        // Given
        
        let fieldValue = "alphazxc"
        let encodedFieldValue = fieldValue.data(using: .ascii)!
        let fieldLength = UInt(encodedFieldValue.count)
        let fieldFormat = ISOStringFormat.a
        
        // When
        
        let (decodeFieldResult, _) = try! AlphaFieldEncoder.decode(data: encodedFieldValue, length: fieldLength, format: fieldFormat)
        
        // Then
        
        XCTAssertEqual(decodeFieldResult, fieldValue)
    }
    
    func testDecodeFieldWithWrongLength() throws {
        
        let fieldValue = "alphazxc"
        let encodedFieldValue = fieldValue.data(using: .ascii)!
        let encodedFieldValueWithWrongLength = encodedFieldValue.subdata(in: Range(0...4))
        let fieldLength = UInt(encodedFieldValue.count)
        let fieldFormat = ISOStringFormat.a
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try AlphaFieldEncoder.decode(data: encodedFieldValueWithWrongLength, length: fieldLength, format: fieldFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testDecodeFieldWithWrongFormat() throws {
        
        // Given
        
        let aValue = "alphazxc".data(using: .ascii)!
        let anValue = "alpha123".data(using: .ascii)!
        let ansValue = "alpha12$".data(using: .ascii)!
        let anValueWithControlCharacter = "alpha12\u{1D}".data(using: .ascii)!
        
        let aFieldFormat: ISOStringFormat = [.a]
        let anFieldFormat: ISOStringFormat = [.a, .n]
        let ansFieldFormat: ISOStringFormat = [.a, .n, .s]
        
        let fieldLength = UInt(aValue.count)
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try AlphaFieldEncoder.decode(data: anValue, length: fieldLength, format: aFieldFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try AlphaFieldEncoder.decode(data: ansValue, length: fieldLength, format: anFieldFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try AlphaFieldEncoder.decode(data: anValueWithControlCharacter, length: fieldLength, format: ansFieldFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
}
