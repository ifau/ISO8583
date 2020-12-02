//
//  ISOMessageSerializerTests.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import XCTest
@testable import ISO8583

final class ISOMessageSerializerTests: XCTestCase {
    
    static var allTests = [
        ("testSerializeLength", testSerializeLength),
        ("testSerializeMTI", testSerializeMTI),
        ("testSerializeBitmap", testSerializeBitmap),
        ("testSerializeFieldAlpha", testSerializeFieldAlpha),
        ("testSerializeFieldBinary", testSerializeFieldBinary),
        ("testSerializeFieldNumeric", testSerializeFieldNumeric),
        ("testSerializeFieldLLVAR", testSerializeFieldLLVAR),
        ("testSerializeFieldLLLVAR", testSerializeFieldLLLVAR),
        ("testSerializeFieldLLBIN", testSerializeFieldLLBIN),
        ("testSerializeFieldLLLBIN", testSerializeFieldLLLBIN),
        ("testSerializeFieldLLNUM", testSerializeFieldLLLNUM),
        ("testSerializeFieldLLLNUM", testSerializeFieldLLLNUM)
    ]
    
    func testSerializeLength() {
        
        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let length : UInt = 256
        let threeBytesASCIILength = "256".data(using: .ascii)!
        let threeBytesBCDLength = Data([0x00, 0x02, 0x56])
        let tenBytesASCIILength = "0000000256".data(using: .ascii)!
        let tenBytesBCDLength = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x56])
        
        // When
        
        let threeBytesASCIILengthResult = try! messageSerializer.serializeLength(length, numberOfBytes: 3, format: .ascii)
        let threeBytesBCDLengthResult = try! messageSerializer.serializeLength(length, numberOfBytes: 3, format: .bcd)
        let tenBytesASCIILengthResult = try! messageSerializer.serializeLength(length, numberOfBytes: 10, format: .ascii)
        let tenBytesBCDLengthResult = try! messageSerializer.serializeLength(length, numberOfBytes: 10, format: .bcd)
        
        // Then
        
        XCTAssertEqual(threeBytesASCIILengthResult, threeBytesASCIILength)
        XCTAssertEqual(threeBytesBCDLengthResult, threeBytesBCDLength)
        XCTAssertEqual(tenBytesASCIILengthResult, tenBytesASCIILength)
        XCTAssertEqual(tenBytesBCDLengthResult, tenBytesBCDLength)
        
        XCTAssertThrowsError(try messageSerializer.serializeLength(1_000, numberOfBytes: 3, format: .ascii)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.lengthIsMoreThanMaximumLengthForDeclaredFormat(_, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeLength(1_000_000, numberOfBytes: 3, format: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.lengthIsMoreThanMaximumLengthForDeclaredFormat(_, _) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeMTI() {
        
        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let value : UInt = 800
        let bcdEncodedValue = Data([0x08, 0x00])
        let asciiEncodedValue = "0800".data(using: .ascii)!
        
        let incorrectValue : UInt = 10_000
        
        // When
        
        let asciiEncodedResult = try! messageSerializer.serializeMTI(value, format: .ascii)
        let bcdEncodedResult = try! messageSerializer.serializeMTI(value, format: .bcd)
        
        // Then
        
        XCTAssertEqual(asciiEncodedResult, asciiEncodedValue)
        XCTAssertEqual(bcdEncodedResult, bcdEncodedValue)
        
        XCTAssertThrowsError(try messageSerializer.serializeMTI(incorrectValue, format: .ascii)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.messageContainIncorrectMTI(_) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeMTI(incorrectValue, format: .bcd)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.messageContainIncorrectMTI(_) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeBitmap() {
        
        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let fieldsSet1 : [UInt] = []
        let fieldsSet1Bitmap = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        let fieldsSet2 : [UInt] = [3, 7, 12, 28, 32, 39, 41, 42, 50, 53, 62]
        let fieldsSet2Bitmap = Data([0x22, 0x10, 0x00, 0x11, 0x02, 0xC0, 0x48, 0x04])
        
        let fieldsSet3 : [UInt] = [121, 122, 123, 124, 125, 126, 127, 128]
        let fieldsSet3Bitmap = Data([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff])
        
        let incorrectFieldsSet : [UInt] = [0, 1]
        
        // When
        
        let serializedBitmapFromSet1 = try! messageSerializer.serializeBitmap(fieldNumbers: fieldsSet1)
        let serializedBitmapFromSet2 = try! messageSerializer.serializeBitmap(fieldNumbers: fieldsSet2)
        let serializedBitmapFromSet3 = try! messageSerializer.serializeBitmap(fieldNumbers: fieldsSet3)
        
        // Then
        
        XCTAssertEqual(serializedBitmapFromSet1, fieldsSet1Bitmap)
        XCTAssertEqual(serializedBitmapFromSet2, fieldsSet2Bitmap)
        XCTAssertEqual(serializedBitmapFromSet3, fieldsSet3Bitmap)
        
        XCTAssertThrowsError(try messageSerializer.serializeBitmap(fieldNumbers: incorrectFieldsSet)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.messageContainIncorrectFieldNumbers(_) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeFieldAlpha() {

        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let aValue = "alphazxc"
        let anValue = "alpha123"
        let ansValue = "alpha12$"
        
        let aValueData = aValue.data(using: .ascii)!
        let anValueData = anValue.data(using: .ascii)!
        let ansValueData = ansValue.data(using: .ascii)!
        
        let aValueWithWrongLength = "alpha"
        let anValueWithControlCharacter = "alpha12\u{1D}"
        
        let fieldLength = UInt(aValue.count)
        let aFieldFormat = ISOFieldFormat.alpha(length: fieldLength, valueFormat: [.a])
        let anFieldFormat = ISOFieldFormat.alpha(length: fieldLength, valueFormat: [.a, .n])
        let ansFieldFormat = ISOFieldFormat.alpha(length: fieldLength, valueFormat: [.a, .n, .s])
        
        // When
        
        let serializeAValueResult = try! messageSerializer.serializeField(value: aValue, format: aFieldFormat)
        let serializeAnValueResult = try! messageSerializer.serializeField(value: anValue, format: anFieldFormat)
        let serializeAnsValueResult = try! messageSerializer.serializeField(value: ansValue, format: ansFieldFormat)
        
        // Then
        
        XCTAssertEqual(serializeAValueResult, aValueData)
        XCTAssertEqual(serializeAnValueResult, anValueData)
        XCTAssertEqual(serializeAnsValueResult, ansValueData)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: aValueWithWrongLength, format: aFieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: anValue, format: aFieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: ansValue, format: anFieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: anValueWithControlCharacter, format: ansFieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeFieldBinary() {
        
        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let binaryFieldValue = "00112233445566778899aabbccddeeff"
        let binaryFieldData = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        
        let binaryFieldValueWithWrongLength = binaryFieldValue.replacingOccurrences(of: "ff", with: "")
        let binaryFieldValueWithNotHexCharacters = binaryFieldValue.replacingOccurrences(of: "ff", with: "xy")
        
        let fieldLength = UInt(binaryFieldData.count)
        let fieldFormat = ISOFieldFormat.binary(length: fieldLength)
        
        // When
        
        let serializeBinaryFieldResult = try! messageSerializer.serializeField(value: binaryFieldValue, format: fieldFormat)
        
        // Then
        
        XCTAssertEqual(serializeBinaryFieldResult, binaryFieldData)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: binaryFieldValueWithWrongLength, format: fieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: binaryFieldValueWithNotHexCharacters, format: fieldFormat)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeFieldNumeric() {

        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let numericFieldValue = "123000000000000000000"
        let numericFieldWithLeftPaddingEncodedData = Data([0x01, 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let numericFieldWithRightPaddingEncodedData = Data([0x12, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        let numericFieldValueWithWrongLength = numericFieldValue.replacingOccurrences(of: "23", with: "")
        let numericFieldValueWithNotNumericCharacters = numericFieldValue.replacingOccurrences(of: "23", with: "xy")
        
        let fieldLength = UInt(numericFieldValue.count)
        let fieldFormatWithLeftPadding = ISOFieldFormat.numeric(length: fieldLength, paddingFormat: .left)
        let fieldFormatWithRightPadding = ISOFieldFormat.numeric(length: fieldLength, paddingFormat: .right)
        
        // When

        let serializeNumericFieldWithLeftPaddingResult = try! messageSerializer.serializeField(value: numericFieldValue, format: fieldFormatWithLeftPadding)
        let serializeNumericFieldWithRightPaddingResult = try! messageSerializer.serializeField(value: numericFieldValue, format: fieldFormatWithRightPadding)
        
        // Then

        XCTAssertEqual(serializeNumericFieldWithLeftPaddingResult, numericFieldWithLeftPaddingEncodedData)
        XCTAssertEqual(serializeNumericFieldWithRightPaddingResult, numericFieldWithRightPaddingEncodedData)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: numericFieldValueWithWrongLength, format: fieldFormatWithLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldLengthIsNotEqualToDeclaredLength(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: numericFieldValueWithNotNumericCharacters, format: fieldFormatWithLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeFieldLLVAR() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "LLVAR_field_value"
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let valueWithControlCharacter = "LLVAR_field_value_\u{1D}"
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "x", count: 100)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "x", count: 100)
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llvar(lengthFormat: .bcd, valueFormat: [.a, .n, .s])
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llvar(lengthFormat: .ascii, valueFormat: [.a, .n, .s])

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueWithControlCharacter, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }

    func testSerializeFieldLLLVAR() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "LLLVAR_field_value"
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x00, 0x18]
        let asciiLength : [UInt8] = Array("018".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let valueWithControlCharacter = "LLLVAR_field_value_\u{1D}"
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "x", count: 10_000)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "x", count: 1_000)
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllvar(lengthFormat: .bcd, valueFormat: [.a, .n, .s])
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllvar(lengthFormat: .ascii, valueFormat: [.a, .n, .s])

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueWithControlCharacter, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }

    func testSerializeFieldLLBIN() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x16]
        let asciiLength : [UInt8] = Array("16".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let valueWithNotHexCharacters = value.replacingOccurrences(of: "FF", with: "XY")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "FF", count: 100)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "FF", count: 100)
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llbin(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llbin(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueWithNotHexCharacters, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }

    func testSerializeFieldLLLBIN() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x00, 0x16]
        let asciiLength : [UInt8] = Array("016".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let valueWithNotHexCharacters = value.replacingOccurrences(of: "FF", with: "XY")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "FF", count: 10_000)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "FF", count: 1_000)
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllbin(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllbin(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueWithNotHexCharacters, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeFieldLLNUM() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "12345678901234567"
        let leftPaddingEncodedData  : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let rightPaddingEncodedData : [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x70]
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)

        let dataWithBCDEncodedLengthAndLeftPadding = Data([bcdLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithBCDEncodedLengthAndRightPadding = Data([bcdLength, rightPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndLeftPadding = Data([asciiLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndRightPadding = Data([asciiLength, rightPaddingEncodedData].flatMap { $0 })
        
        let valueWithNotNumericCharacters = value.replacingOccurrences(of: "01", with: "xy")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "99", count: 100)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "99", count: 100)
        
        let fieldFormatWithBCDEncodedLengthAndLeftPadding = ISOFieldFormat.llnum(lengthFormat: .bcd, paddingFormat: .left)
        let fieldFormatWithBCDEncodedLengthAndRightPadding = ISOFieldFormat.llnum(lengthFormat: .bcd, paddingFormat: .right)
        let fieldFormatWithASCIIEncodedLengthAndLeftPadding = ISOFieldFormat.llnum(lengthFormat: .ascii, paddingFormat: .left)
        let fieldFormatWithASCIIEncodedLengthAndRightPadding = ISOFieldFormat.llnum(lengthFormat: .ascii, paddingFormat: .right)
        
        // When

        let serializeDataWithBCDEncodedLengthAndLeftPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLengthAndLeftPadding)
        let serializeDataWithBCDEncodedLengthAndRightPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLengthAndRightPadding)
        let serializeDataWithASCIIEncodedLengthAndLeftPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLengthAndLeftPadding)
        let serializeDataWithASCIIEncodedLengthAndRightPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLengthAndRightPadding)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthAndLeftPaddingResult, dataWithBCDEncodedLengthAndLeftPadding)
        XCTAssertEqual(serializeDataWithBCDEncodedLengthAndRightPaddingResult, dataWithBCDEncodedLengthAndRightPadding)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthAndLeftPaddingResult, dataWithASCIIEncodedLengthAndLeftPadding)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthAndRightPaddingResult, dataWithASCIIEncodedLengthAndRightPadding)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueWithNotNumericCharacters, format: fieldFormatWithBCDEncodedLengthAndLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxBCDEncodedLength, format: fieldFormatWithBCDEncodedLengthAndLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLengthAndLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
    
    func testSerializeFieldLLLNUM() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "12345678901234567"
        let leftPaddingEncodedData  : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let rightPaddingEncodedData : [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x70]
        let bcdLength : [UInt8] = [0x00, 0x17]
        let asciiLength : [UInt8] = Array("017".utf8)

        let dataWithBCDEncodedLengthAndLeftPadding = Data([bcdLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithBCDEncodedLengthAndRightPadding = Data([bcdLength, rightPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndLeftPadding = Data([asciiLength, leftPaddingEncodedData].flatMap { $0 })
        let dataWithASCIIEncodedLengthAndRightPadding = Data([asciiLength, rightPaddingEncodedData].flatMap { $0 })
        
        let valueWithNotNumericCharacters = value.replacingOccurrences(of: "01", with: "xy")
        let valueMoreThanMaxBCDEncodedLength = String(repeating: "99", count: 10_000)
        let valueMoreThanMaxASCIIEncodedLength = String(repeating: "99", count: 1_000)
        
        let fieldFormatWithBCDEncodedLengthAndLeftPadding = ISOFieldFormat.lllnum(lengthFormat: .bcd, paddingFormat: .left)
        let fieldFormatWithBCDEncodedLengthAndRightPadding = ISOFieldFormat.lllnum(lengthFormat: .bcd, paddingFormat: .right)
        let fieldFormatWithASCIIEncodedLengthAndLeftPadding = ISOFieldFormat.lllnum(lengthFormat: .ascii, paddingFormat: .left)
        let fieldFormatWithASCIIEncodedLengthAndRightPadding = ISOFieldFormat.lllnum(lengthFormat: .ascii, paddingFormat: .right)
        
        // When

        let serializeDataWithBCDEncodedLengthAndLeftPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLengthAndLeftPadding)
        let serializeDataWithBCDEncodedLengthAndRightPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLengthAndRightPadding)
        let serializeDataWithASCIIEncodedLengthAndLeftPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLengthAndLeftPadding)
        let serializeDataWithASCIIEncodedLengthAndRightPaddingResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLengthAndRightPadding)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthAndLeftPaddingResult, dataWithBCDEncodedLengthAndLeftPadding)
        XCTAssertEqual(serializeDataWithBCDEncodedLengthAndRightPaddingResult, dataWithBCDEncodedLengthAndRightPadding)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthAndLeftPaddingResult, dataWithASCIIEncodedLengthAndLeftPadding)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthAndRightPaddingResult, dataWithASCIIEncodedLengthAndRightPadding)
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueWithNotNumericCharacters, format: fieldFormatWithBCDEncodedLengthAndLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsNotConformToDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxBCDEncodedLength, format: fieldFormatWithBCDEncodedLengthAndLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try messageSerializer.serializeField(value: valueMoreThanMaxASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLengthAndLeftPadding)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.fieldValueIsMoreThanMaximumLengthForDeclaredFormat(_, _, _) = reason else { return XCTFail() }
        }
    }
}
