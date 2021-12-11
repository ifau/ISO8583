//
//  VariableAlphaFieldEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import XCTest
@testable import ISO8583

class VariableAlphaFieldEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectLLVARField", testEncodeCorrectLLVARField),
        ("testEncodeCorrectLLLVARField", testEncodeCorrectLLLVARField),
        ("testEncodeIncorrectLLVARField", testEncodeIncorrectLLVARField),
        ("testEncodeIncorrectLLLVARField", testEncodeIncorrectLLLVARField),
        
        ("testDecodeCorrectLLVARField", testDecodeCorrectLLVARField),
        ("testDecodeCorrectLLLVARField", testDecodeCorrectLLLVARField),
        ("testDecodeIncorrectLLVARField", testDecodeIncorrectLLVARField),
        ("testDecodeIncorrectLLLVARField", testDecodeIncorrectLLLVARField)
    ]
    
    // MARK: - Encode Field Tests
    
    func testEncodeCorrectLLVARField() throws {
        
        // Given
        
        let value = "LLVAR_field_value"
        let valueFormat: ISOStringFormat = [.a, .n, .s]
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        // When

        let encodeDataWithBCDEncodedLengthResult = try VariableAlphaFieldEncoder.encode(value: value, numberOfBytesForLength: 1, lengthFormat: .bcd, valueFormat: valueFormat)
        let encodeDataWithASCIIEncodedLengthResult = try VariableAlphaFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .ascii, valueFormat: valueFormat)

        // Then

        XCTAssertEqual(encodeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
    }
    
    func testEncodeIncorrectLLVARField() throws {
        
        // Given
        
        let valueWithControlCharacter = "LLVAR_field_value_\u{1D}"
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "x", count: 100)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "x", count: 100)
        let valueFormat: ISOStringFormat = [.a, .n, .s]
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.encode(value: valueWithControlCharacter, numberOfBytesForLength: 1, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.encode(value: valueMoreThanMaxBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.encode(value: valueMoreThanMaxASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii, valueFormat: valueFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testEncodeCorrectLLLVARField() throws {
        
        // Given

        let value = "LLLVAR_field_value"
        let valueFormat: ISOStringFormat = [.a, .n, .s]
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x00, 0x18]
        let asciiLength : [UInt8] = Array("018".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        // When

        let encodeDataWithBCDEncodedLengthResult = try? VariableAlphaFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .bcd, valueFormat: valueFormat)
        let encodeDataWithASCIIEncodedLengthResult = try? VariableAlphaFieldEncoder.encode(value: value, numberOfBytesForLength: 3, lengthFormat: .ascii, valueFormat: valueFormat)

        // Then

        XCTAssertEqual(encodeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
    }
    
    func testEncodeIncorrectLLLVARField() throws {
        
        // Given
        
        let valueWithControlCharacter = "LLLVAR_field_value_\u{1D}"
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "x", count: 10_000)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "x", count: 1_000)
        let valueFormat: ISOStringFormat = [.a, .n, .s]

        // When

        // Then

        XCTAssertThrowsError(try VariableAlphaFieldEncoder.encode(value: valueWithControlCharacter, numberOfBytesForLength: 2, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.encode(value: valueMoreThanMaxBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.encode(value: valueMoreThanMaxASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii, valueFormat: valueFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Decode Field Tests
    
    func testDecodeCorrectLLVARField() throws {
        
        let value = "LLVAR_field_value"
        let valueFormat: ISOStringFormat = [.a, .n, .s]
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        // When
        
        let (decodeDataWithBCDEncodedLengthResult, _) = try! VariableAlphaFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd, valueFormat: valueFormat)
        let (decodeDataWithASCIIEncodedLengthResult, _) = try! VariableAlphaFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii, valueFormat: valueFormat)
        
        // Then
        
        XCTAssertEqual(decodeDataWithBCDEncodedLengthResult, value)
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthResult, value)
    }
    
    func testDecodeIncorrectLLVARField() throws {
        
        // Given
        
        let value = "LLVAR_field_value"
        let valueFormat: ISOStringFormat = [.a, .n, .s]
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)
        
        let dataWithNotEnougthBytesForBCDLength = Data()
        let dataWithNotEnougthBytesForASCIILength = "1".data(using: .ascii)!
        let dataWithLessBytesForValueThanBCDEncodedLength = Data([bcdLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithLessBytesForValueThanASCIIEncodedLength = Data([asciiLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithControlCharacter = Data([bcdLength, [0x1D], valueData].flatMap { $0 })
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithNotEnougthBytesForBCDLength, numberOfBytesForLength: 1, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithNotEnougthBytesForASCIILength, numberOfBytesForLength: 2, lengthFormat: .ascii, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithLessBytesForValueThanBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithLessBytesForValueThanASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithControlCharacter, numberOfBytesForLength: 1, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testDecodeCorrectLLLVARField() throws {
        
        // Given
        
        let value = "LLLVAR_field_value"
        let valueFormat: ISOStringFormat = [.a, .n, .s]
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x00, 0x18]
        let asciiLength : [UInt8] = Array("018".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        // When
        
        let (decodeDataWithBCDEncodedLengthResult, _) = try! VariableAlphaFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd, valueFormat: valueFormat)
        let (decodeDataWithASCIIEncodedLengthResult, _) = try! VariableAlphaFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii, valueFormat: valueFormat)
        
        // Then
        
        XCTAssertEqual(decodeDataWithBCDEncodedLengthResult, value)
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthResult, value)
    }
    
    func testDecodeIncorrectLLLVARField() throws {
        
        // Given
        
        let value = "LLLVAR_field_value"
        let valueFormat: ISOStringFormat = [.a, .n, .s]
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x00, 0x18]
        let asciiLength : [UInt8] = Array("018".utf8)
        
        let dataWithNotEnougthBytesForBCDLength = Data([0x00])
        let dataWithNotEnougthBytesForASCIILength = "01".data(using: .ascii)!
        let dataWithLessBytesForValueThanBCDEncodedLength = Data([bcdLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithLessBytesForValueThanASCIIEncodedLength = Data([asciiLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithControlCharacter = Data([bcdLength, [0x1D], valueData].flatMap { $0 })
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithNotEnougthBytesForBCDLength, numberOfBytesForLength: 2, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithNotEnougthBytesForASCIILength, numberOfBytesForLength: 3, lengthFormat: .ascii, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithLessBytesForValueThanBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithLessBytesForValueThanASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableAlphaFieldEncoder.decode(data: dataWithControlCharacter, numberOfBytesForLength: 2, lengthFormat: .bcd, valueFormat: valueFormat)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
}
