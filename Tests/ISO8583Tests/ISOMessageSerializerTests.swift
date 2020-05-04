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
    }
    
    func testSerializeMTI() {
        
        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let value : UInt = 800
        let bcdEncodedMTI = Data([0x08, 0x00])
        let asciiEncodedMTI = "0800".data(using: .ascii)!
        
        // When
        
        let asciiEncodedResult = try! messageSerializer.serializeMTI(value, format: .ascii)
        let bcdEncodedResult = try! messageSerializer.serializeMTI(value, format: .bcd)
        
        // Then
        
        XCTAssertEqual(asciiEncodedResult, asciiEncodedMTI)
        XCTAssertEqual(bcdEncodedResult, bcdEncodedMTI)
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
        
        // When
        
        let serializedBitmapFromSet1 = try! messageSerializer.serializeBitmap(fieldNumbers: fieldsSet1)
        let serializedBitmapFromSet2 = try! messageSerializer.serializeBitmap(fieldNumbers: fieldsSet2)
        let serializedBitmapFromSet3 = try! messageSerializer.serializeBitmap(fieldNumbers: fieldsSet3)
        
        // Then
        
        XCTAssertEqual(serializedBitmapFromSet1, fieldsSet1Bitmap)
        XCTAssertEqual(serializedBitmapFromSet2, fieldsSet2Bitmap)
        XCTAssertEqual(serializedBitmapFromSet3, fieldsSet3Bitmap)
    }
    
    func testSerializeFieldAlpha() {

        // Given
        
        let messageSerializer = ISOMessageSerializer()

        let alphaFieldValue = "alpha_field_value"
        let alphaFieldData = alphaFieldValue.data(using: .ascii)!

        let fieldLength = UInt(alphaFieldValue.count)
        let fieldFormat = ISOFieldFormat.alpha(length: fieldLength)

        // When

        let serializeAlphaFieldResult = try! messageSerializer.serializeField(value: alphaFieldValue, format: fieldFormat)

        // Then

        XCTAssertEqual(serializeAlphaFieldResult, alphaFieldData)
    }
    
    func testSerializeFieldBinary() {
        
        // Given
        
        let messageSerializer = ISOMessageSerializer()
        
        let binaryFieldValue = "00112233445566778899aabbccddeeff"
        let binaryFieldData = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        
        let fieldLength = UInt(binaryFieldData.count)
        let fieldFormat = ISOFieldFormat.binary(length: fieldLength)
        
        // When
        
        let serializeBinaryFieldResult = try! messageSerializer.serializeField(value: binaryFieldValue, format: fieldFormat)
        
        // Then
        
        XCTAssertEqual(serializeBinaryFieldResult, binaryFieldData)
    }
    
    func testSerializeFieldNumeric() {

        // Given
        
        let messageSerializer = ISOMessageSerializer()

        let numericFieldValue = "123"
        let numericFieldEncodedData = Data([0x01, 0x23])

        let fieldLength = UInt(numericFieldValue.count)
        let fieldFormat = ISOFieldFormat.numeric(length: fieldLength)
        
        // When

        let serializeNumericFieldResult = try! messageSerializer.serializeField(value: numericFieldValue, format: fieldFormat)
        
        // Then

        XCTAssertEqual(serializeNumericFieldResult, numericFieldEncodedData)
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

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llvar(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llvar(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
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

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllvar(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllvar(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
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

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llbin(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llbin(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
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

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllbin(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllbin(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
    }
    
    func testSerializeFieldLLNUM() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "012345678901234567"
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let bcdLength : [UInt8] = [0x18]
        let asciiLength : [UInt8] = Array("18".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llnum(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llnum(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
    }
    
    func testSerializeFieldLLLNUM() {

        // Given

        let messageSerializer = ISOMessageSerializer()

        let value = "012345678901234567"
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let bcdLength : [UInt8] = [0x00, 0x18]
        let asciiLength : [UInt8] = Array("018".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllnum(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllnum(lengthFormat: .ascii)

        // When

        let serializeDataWithBCDEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithBCDEncodedLength)
        let serializeDataWithASCIIEncodedLengthResult = try! messageSerializer.serializeField(value: value, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(serializeDataWithBCDEncodedLengthResult, dataWithBCDEncodedLength)
        XCTAssertEqual(serializeDataWithASCIIEncodedLengthResult, dataWithASCIIEncodedLength)
    }
}
