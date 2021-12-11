//
//  VariableNumericFieldEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import XCTest
@testable import ISO8583

class VariableNumericFieldEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectLLNUMField", testEncodeCorrectLLNUMField),
        ("testEncodeCorrectLLLNUMField", testEncodeCorrectLLLNUMField),
        ("testEncodeIncorrectLLNUMField", testEncodeIncorrectLLNUMField),
        ("testEncodeIncorrectLLLNUMField", testEncodeIncorrectLLLNUMField),
        
        ("testDecodeCorrectLLNUMField", testDecodeCorrectLLNUMField),
        ("testDecodeCorrectLLLNUMField", testDecodeCorrectLLLNUMField),
        ("testDecodeIncorrectLLNUMField", testDecodeIncorrectLLNUMField),
        ("testDecodeIncorrectLLLNUMField", testDecodeIncorrectLLLNUMField)
    ]
    
    // MARK: - Encode Field Tests
    
    func testEncodeCorrectLLNUMField() throws {
        
        // Given

        let value = "12345678901234567"
        let leftPaddingEncodedData  : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let rightPaddingEncodedData : [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x70]
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)

        let dataWithBCDEncodedLengthAndLeftPadding = Data([bcdLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithBCDEncodedLengthAndRightPadding = Data([bcdLength, rightPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndLeftPadding = Data([asciiLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndRightPadding = Data([asciiLength, rightPaddingEncodedData].flatMap { $0 })
        
        // When

        let encodeDataWithBCDEncodedLengthAndLeftPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .left)
        let encodeDataWithBCDEncodedLengthAndRightPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .right)
        let encodeDataWithASCIIEncodedLengthAndLeftPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .ascii, padding: .left)
        let encodeDataWithASCIIEncodedLengthAndRightPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .ascii, padding: .right)

        // Then

        XCTAssertEqual(encodeDataWithBCDEncodedLengthAndLeftPaddingResult, dataWithBCDEncodedLengthAndLeftPadding)
        XCTAssertEqual(encodeDataWithBCDEncodedLengthAndRightPaddingResult, dataWithBCDEncodedLengthAndRightPadding)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthAndLeftPaddingResult, dataWithASCIIEncodedLengthAndLeftPadding)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthAndRightPaddingResult, dataWithASCIIEncodedLengthAndRightPadding)
    }
    
    func testEncodeIncorrectLLNUMField() throws {
        
        // Given
        
        let value = "12345678901234567"
        let valueWithNotNumericCharacters = value.replacingOccurrences(of: "01", with: "xy")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "99", count: 100)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "99", count: 100)
        
        // When

        // Then
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.encode(value: valueWithNotNumericCharacters, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.encode(value: valueMoreThanMaxBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.encode(value: valueMoreThanMaxASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii, padding: .left)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testEncodeCorrectLLLNUMField() throws {
        
        // Given

        let value = "12345678901234567"
        let leftPaddingEncodedData  : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let rightPaddingEncodedData : [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x70]
        let bcdLength : [UInt8] = [0x00, 0x17]
        let asciiLength : [UInt8] = Array("017".utf8)

        let dataWithBCDEncodedLengthAndLeftPadding = Data([bcdLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithBCDEncodedLengthAndRightPadding = Data([bcdLength, rightPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndLeftPadding = Data([asciiLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndRightPadding = Data([asciiLength, rightPaddingEncodedData].flatMap { $0 })
        
        // When

        let encodeDataWithBCDEncodedLengthAndLeftPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .left)
        let encodeDataWithBCDEncodedLengthAndRightPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .right)
        let encodeDataWithASCIIEncodedLengthAndLeftPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 3, lengthFormat: .ascii, padding: .left)
        let encodeDataWithASCIIEncodedLengthAndRightPaddingResult = try? VariableNumericFieldEncoder.encode(value: value, numberOfBytesForLength: 3, lengthFormat: .ascii, padding: .right)

        // Then

        XCTAssertEqual(encodeDataWithBCDEncodedLengthAndLeftPaddingResult, dataWithBCDEncodedLengthAndLeftPadding)
        XCTAssertEqual(encodeDataWithBCDEncodedLengthAndRightPaddingResult, dataWithBCDEncodedLengthAndRightPadding)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthAndLeftPaddingResult, dataWithASCIIEncodedLengthAndLeftPadding)
        XCTAssertEqual(encodeDataWithASCIIEncodedLengthAndRightPaddingResult, dataWithASCIIEncodedLengthAndRightPadding)
    }
    
    func testEncodeIncorrectLLLNUMField() throws {
        
        // Given
        
        let value = "12345678901234567"
        let valueWithNotNumericCharacters = value.replacingOccurrences(of: "01", with: "xy")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "99", count: 10_000)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "99", count: 1_000)
        
        // When

        // Then
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.encode(value: valueWithNotNumericCharacters, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.encode(value: valueMoreThanMaxBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.encode(value: valueMoreThanMaxASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii, padding: .left)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Decode Field Tests
    
    func testDecodeCorrectLLNUMField() throws {
        
        // Given
        
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let valueWithLeftPadding  = "12345678901234567"
        let valueWithRightPadding = "01234567890123456"
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        // When

        let (decodeDataWithBCDEncodedLengthAndLeftPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .left)
        let (decodeDataWithBCDEncodedLengthAndRightPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .right)
        let (decodeDataWithASCIIEncodedLengthAndLeftPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii, padding: .left)
        let (decodeDataWithASCIIEncodedLengthAndRightPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii, padding: .right)

        // Then

        XCTAssertEqual(decodeDataWithBCDEncodedLengthAndLeftPaddingResult, valueWithLeftPadding)
        XCTAssertEqual(decodeDataWithBCDEncodedLengthAndRightPaddingResult, valueWithRightPadding)
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthAndLeftPaddingResult, valueWithLeftPadding)
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthAndRightPaddingResult, valueWithRightPadding)
    }
    
    func testDecodeIncorrectLLNUMField() throws {
        
        // Given
        
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)
        
        let dataWithNotEnougthBytesForBCDLength = Data()
        let dataWithNotEnougthBytesForASCIILength = "1".data(using: .ascii)!
        let dataWithLessBytesForValueThanBCDEncodedLength = Data([bcdLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithLessBytesForValueThanASCIIEncodedLength = Data([asciiLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithNotNumericCharacter = Data([bcdLength, [0xcf], valueData].flatMap { $0 })
        
        // When

        // Then
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithNotEnougthBytesForBCDLength, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithNotEnougthBytesForASCIILength, numberOfBytesForLength: 2, lengthFormat: .ascii, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithLessBytesForValueThanBCDEncodedLength, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithLessBytesForValueThanASCIIEncodedLength, numberOfBytesForLength: 2, lengthFormat: .ascii, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithNotNumericCharacter, numberOfBytesForLength: 1, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testDecodeCorrectLLLNUMField() throws {
        
        // Given
        
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let valueWithLeftPadding  = "12345678901234567"
        let valueWithRightPadding = "01234567890123456"
        let bcdLength : [UInt8] = [0x00, 0x17]
        let asciiLength : [UInt8] = Array("017".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        // When

        let (decodeDataWithBCDEncodedLengthAndLeftPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .left)
        let (decodeDataWithBCDEncodedLengthAndRightPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .right)
        let (decodeDataWithASCIIEncodedLengthAndLeftPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii, padding: .left)
        let (decodeDataWithASCIIEncodedLengthAndRightPaddingResult, _) = try! VariableNumericFieldEncoder.decode(data: dataWithASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii, padding: .right)

        // Then

        XCTAssertEqual(decodeDataWithBCDEncodedLengthAndLeftPaddingResult, valueWithLeftPadding)
        XCTAssertEqual(decodeDataWithBCDEncodedLengthAndRightPaddingResult, valueWithRightPadding)
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthAndLeftPaddingResult, valueWithLeftPadding)
        XCTAssertEqual(decodeDataWithASCIIEncodedLengthAndRightPaddingResult, valueWithRightPadding)
    }
    
    func testDecodeIncorrectLLLNUMField() throws {
        
        // Given
        
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let bcdLength : [UInt8] = [0x00, 0x17]
        let asciiLength : [UInt8] = Array("017".utf8)
        
        let dataWithNotEnougthBytesForBCDLength = Data([0x00])
        let dataWithNotEnougthBytesForASCIILength = "01".data(using: .ascii)!
        let dataWithLessBytesForValueThanBCDEncodedLength = Data([bcdLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithLessBytesForValueThanASCIIEncodedLength = Data([asciiLength, Array(valueData[0...4])].flatMap { $0 })
        let dataWithNotNumericCharacter = Data([bcdLength, [0xcf], valueData].flatMap { $0 })
        
        // When

        // Then
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithNotEnougthBytesForBCDLength, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithNotEnougthBytesForASCIILength, numberOfBytesForLength: 3, lengthFormat: .ascii, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeFieldLength(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithLessBytesForValueThanBCDEncodedLength, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithLessBytesForValueThanASCIIEncodedLength, numberOfBytesForLength: 3, lengthFormat: .ascii, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsLessThanDecodedLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try VariableNumericFieldEncoder.decode(data: dataWithNotNumericCharacter, numberOfBytesForLength: 2, lengthFormat: .bcd, padding: .left)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
}
