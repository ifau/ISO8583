//
//  ISOMessageDeserializerTests.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 01/05/2020.
//

import XCTest
@testable import ISO8583

final class ISOMessageDeserializerTests: XCTestCase {
    
    static var allTests = [
        ("testReadLength", testReadLength),
        ("testReadMTI", testReadMTI),
        ("testReadBitmap", testReadBitmap),
        ("testReadFieldAlpha", testReadFieldAlpha),
        ("testReadFieldBinary", testReadFieldBinary),
        ("testReadFieldNumeric", testReadFieldNumeric),
        ("testReadFieldLLVAR", testReadFieldLLVAR),
        ("testReadFieldLLLVAR", testReadFieldLLLVAR),
        ("testReadFieldLLBIN", testReadFieldLLBIN),
        ("testReadFieldLLLBIN", testReadFieldLLLBIN),
        ("testReadFieldLLNUM", testReadFieldLLLNUM),
        ("testReadFieldLLLNUM", testReadFieldLLLNUM)
    ]
    
    func testReadLength() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let bcdEncodedData = Data([0x15, 0x44, 0x02])
        let asciiEncodedData = "154402".data(using: .ascii)!
        let value : UInt = 154402
        
        // When
        
        let bcdDecodedResult = try! messageDeserializer.readLength(data: bcdEncodedData, format: .bcd)
        let asciiDecodedResult = try! messageDeserializer.readLength(data: asciiEncodedData, format: .ascii)
        
        // Then
        
        XCTAssertEqual(bcdDecodedResult, value)
        XCTAssertEqual(asciiDecodedResult, value)
    }
    
    func testReadMTI() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let bcdEncodedData = Data([0x08, 0x00])
        let asciiEncodedData = "0800".data(using: .ascii)!
        let value : UInt = 800
        
        // When
        
        let (bcdDecodedResult, _) = try! messageDeserializer.readMTI(data: bcdEncodedData, format: .bcd)
        let (asciiDecodedResult, _) = try! messageDeserializer.readMTI(data: asciiEncodedData, format: .ascii)
        
        // Then
        
        XCTAssertEqual(bcdDecodedResult, value)
        XCTAssertEqual(asciiDecodedResult, value)
    }
    
    func testReadBitmap() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let primaryBitmap                     : [UInt8] = [0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        let primaryBitMapWithSecondaryBitmap  : [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        let emptyBytes                        : [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        let data1 = Data([primaryBitmap, emptyBytes, emptyBytes].flatMap { $0 })
        let data2 = Data([primaryBitMapWithSecondaryBitmap, emptyBytes].flatMap { $0 })
        
        // When
        
        let (bitmapFromData1, _) = try! messageDeserializer.readBitmap(data: data1)
        let (bitmapFromData2, _) = try! messageDeserializer.readBitmap(data: data2)
        
        // Then
        
        XCTAssertEqual(bitmapFromData1, primaryBitmap)
        XCTAssertEqual(bitmapFromData2, primaryBitMapWithSecondaryBitmap)
    }
    
    func testReadFieldAlpha() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let alphaFieldValue = "alpha_field_value"
        let alphaFieldData = alphaFieldValue.data(using: .ascii)!
        
        let fieldLength = UInt(alphaFieldValue.count)
        let fieldFormat = ISOFieldFormat.alpha(length: fieldLength, valueFormat: [.a, .n, .s])
        
        // When
        
        let (readAlphaFieldResult, _) = try! messageDeserializer.readField(data: alphaFieldData, format: fieldFormat)
        
        // Then
        
        XCTAssertEqual(readAlphaFieldResult, alphaFieldValue)
    }
    
    func testReadFieldBinary() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let binaryFieldValue = "00112233445566778899aabbccddeeff"
        let binaryFieldData = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
        
        let fieldLength = UInt(binaryFieldData.count)
        let fieldFormat = ISOFieldFormat.binary(length: fieldLength)
        
        // When
        
        let (readBinaryFieldResult, _) = try! messageDeserializer.readField(data: binaryFieldData, format: fieldFormat)
        
        // Then
        
        XCTAssertEqual(readBinaryFieldResult.lowercased(), binaryFieldValue)
    }

    func testReadFieldNumeric() {

        // Given
        
        let messageDeserializer = ISOMessageDeserializer()

        let numericFieldValue = "123"
        let numericFieldEncodedData = Data([0x01, 0x23])

        let fieldLength = UInt(numericFieldValue.count)
        let fieldFormat = ISOFieldFormat.numeric(length: fieldLength)
        
        // When

        let (readNumericFieldResult, _) = try! messageDeserializer.readField(data: numericFieldEncodedData, format: fieldFormat)
        
        // Then

        XCTAssertEqual(readNumericFieldResult, numericFieldValue)
    }
    
    func testReadFieldLLVAR() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let value = "LLVAR_field_value"
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x17]
        let asciiLength : [UInt8] = Array("17".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llvar(lengthFormat: .bcd, valueFormat: [.a, .n, .s])
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llvar(lengthFormat: .ascii, valueFormat: [.a, .n, .s])
        
        // When
        
        let (readDataWithBCDEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)
        let (readDataWithASCIIEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)
        
        // Then
        
        XCTAssertEqual(readDataWithBCDEncodedLengthResult, value)
        XCTAssertEqual(readDataWithASCIIEncodedLengthResult, value)
    }
    
    func testReadFieldLLLVAR() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let value = "LLLVAR_field_value"
        let valueData : [UInt8] = Array(value.utf8)
        let bcdLength : [UInt8] = [0x00, 0x18]
        let asciiLength : [UInt8] = Array("018".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllvar(lengthFormat: .bcd, valueFormat: [.a, .n, .s])
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllvar(lengthFormat: .ascii, valueFormat: [.a, .n, .s])
        
        // When
        
        let (readDataWithBCDEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)
        let (readDataWithASCIIEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)
        
        // Then
        
        XCTAssertEqual(readDataWithBCDEncodedLengthResult, value)
        XCTAssertEqual(readDataWithASCIIEncodedLengthResult, value)
    }
    
    func testReadFieldLLBIN() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x16]
        let asciiLength : [UInt8] = Array("16".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llbin(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llbin(lengthFormat: .ascii)
        
        // When
        
        let (readDataWithBCDEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)
        let (readDataWithASCIIEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)
        
        // Then
        
        XCTAssertEqual(readDataWithBCDEncodedLengthResult.uppercased(), value)
        XCTAssertEqual(readDataWithASCIIEncodedLengthResult.uppercased(), value)
    }
    
    func testReadFieldLLLBIN() {
        
        // Given
        
        let messageDeserializer = ISOMessageDeserializer()
        
        let value = "00112233445566778899AABBCCDDEEFF"
        let valueData : [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        let bcdLength : [UInt8] = [0x00, 0x16]
        let asciiLength : [UInt8] = Array("016".utf8)
        
        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })
        
        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllbin(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllbin(lengthFormat: .ascii)
        
        // When
        
        let (readDataWithBCDEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)
        let (readDataWithASCIIEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)
        
        // Then
        
        XCTAssertEqual(readDataWithBCDEncodedLengthResult.uppercased(), value)
        XCTAssertEqual(readDataWithASCIIEncodedLengthResult.uppercased(), value)
    }
    
    func testReadFieldLLNUM() {

        // Given

        let messageDeserializer = ISOMessageDeserializer()

        let value = "012345678901234567"
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let bcdLength : [UInt8] = [0x18]
        let asciiLength : [UInt8] = Array("18".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.llnum(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.llnum(lengthFormat: .ascii)

        // When

        let (readDataWithBCDEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)
        let (readDataWithASCIIEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(readDataWithBCDEncodedLengthResult, value)
        XCTAssertEqual(readDataWithASCIIEncodedLengthResult, value)
    }
    
    func testReadFieldLLLNUM() {

        // Given

        let messageDeserializer = ISOMessageDeserializer()

        let value = "012345678901234567"
        let valueData : [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0x01, 0x23, 0x45, 0x67]
        let bcdLength : [UInt8] = [0x00, 0x18]
        let asciiLength : [UInt8] = Array("018".utf8)

        let dataWithBCDEncodedLength = Data([bcdLength, valueData].flatMap { $0 })
        let dataWithASCIIEncodedLength = Data([asciiLength, valueData].flatMap { $0 })

        let fieldFormatWithBCDEncodedLength = ISOFieldFormat.lllnum(lengthFormat: .bcd)
        let fieldFormatWithASCIIEncodedLength = ISOFieldFormat.lllnum(lengthFormat: .ascii)

        // When

        let (readDataWithBCDEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithBCDEncodedLength, format: fieldFormatWithBCDEncodedLength)
        let (readDataWithASCIIEncodedLengthResult, _) = try! messageDeserializer.readField(data: dataWithASCIIEncodedLength, format: fieldFormatWithASCIIEncodedLength)

        // Then

        XCTAssertEqual(readDataWithBCDEncodedLengthResult, value)
        XCTAssertEqual(readDataWithASCIIEncodedLengthResult, value)
    }
}
