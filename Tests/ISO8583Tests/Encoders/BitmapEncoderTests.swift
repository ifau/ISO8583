//
//  BitmapEncoderTests.swift
//  ISO8583Tests
//
//  Created by Evgeny Seliverstov on 08/12/2021.
//

import XCTest
@testable import ISO8583

class BitmapEncoderTests: XCTestCase {
    
    static var allTests = [
        ("testEncodeCorrectBitmap", testEncodeCorrectBitmap),
        ("testEncodeIncorrectBitmap", testEncodeIncorrectBitmap),
        
        ("testDecodeCorrectBitmap", testDecodeCorrectBitmap),
        ("testDecodeIncorrectBitmap", testDecodeIncorrectBitmap)
    ]
    
    // MARK: - Encode Tests
    
    func testEncodeCorrectBitmap() {
        
        // Given
        
        let fieldsSet1 : [UInt] = []
        let fieldsSet1Bitmap = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        let fieldsSet2 : [UInt] = [3, 7, 12, 28, 32, 39, 41, 42, 50, 53, 62]
        let fieldsSet2Bitmap = Data([0x22, 0x10, 0x00, 0x11, 0x02, 0xC0, 0x48, 0x04])
        
        let fieldsSet3 : [UInt] = [121, 122, 123, 124, 125, 126, 127, 128]
        let fieldsSet3Bitmap = Data([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff])
        
        // When
        
        let encodedBitmapFromSet1 = try? BitmapEncoder.encode(fieldNumbers: fieldsSet1)
        let encodedBitmapFromSet2 = try? BitmapEncoder.encode(fieldNumbers: fieldsSet2)
        let encodedBitmapFromSet3 = try? BitmapEncoder.encode(fieldNumbers: fieldsSet3)
        
        // Then
        
        XCTAssertEqual(encodedBitmapFromSet1, fieldsSet1Bitmap)
        XCTAssertEqual(encodedBitmapFromSet2, fieldsSet2Bitmap)
        XCTAssertEqual(encodedBitmapFromSet3, fieldsSet3Bitmap)
    }
    
    func testEncodeIncorrectBitmap() {
        
        let incorrectFieldsSet : [UInt] = [0, 1]
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try BitmapEncoder.encode(fieldNumbers: incorrectFieldsSet)) { error in
            guard case ISOError.serializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.SerializeMessageFailureReason.messageContainIncorrectFieldNumbers(_) = reason else { return XCTFail() }
        }
    }
    
    // MARK: - Encode Tests
    
    func testDecodeCorrectBitmap() {
        
        let primaryBitmap                     : [UInt8] = [0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        let primaryBitMapWithSecondaryBitmap  : [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        
        let data1 = Data(primaryBitmap)
        let data2 = Data(primaryBitMapWithSecondaryBitmap)
        
        // When
        
        let (bitmapFromData1, _) = try! BitmapEncoder.decode(from: data1)
        let (bitmapFromData2, _) = try! BitmapEncoder.decode(from: data2)
        
        // Then
        
        XCTAssertEqual(bitmapFromData1, primaryBitmap)
        XCTAssertEqual(bitmapFromData2, primaryBitMapWithSecondaryBitmap)
    }
    
    func testDecodeIncorrectBitmap() {
        
        // Given
        
        let primaryBitmap                     : [UInt8] = [0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        let primaryBitMapWithSecondaryBitmap  : [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        
        let data1 = Data(primaryBitmap)
        let data2 = Data(primaryBitMapWithSecondaryBitmap)
        
        let dataWithNotEnougthBytesForPrimaryBitmap = data1.subdata(in: Range(0...4))
        let dataWithNotEnougthBytesForSecondaryBitmap = data2.subdata(in: Range(0...12))
        
        // When
        
        // Then
        
        XCTAssertThrowsError(try BitmapEncoder.decode(from: dataWithNotEnougthBytesForPrimaryBitmap)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodePrimaryBitmap = reason else { return XCTFail() }
        }
        
        XCTAssertThrowsError(try BitmapEncoder.decode(from: dataWithNotEnougthBytesForSecondaryBitmap)) { error in
            guard case ISOError.deserializeMessageFailed(let reason) = error else { return XCTFail() }
            guard case ISOError.DeserializeMessageFailureReason.notEnoughDataForDecodeSecondaryBitmap = reason else { return XCTFail() }
        }
    }
}
