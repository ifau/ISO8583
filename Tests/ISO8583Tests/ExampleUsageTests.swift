//
//  ExampleUsageTests.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 03/05/2020.
//

import XCTest
@testable import ISO8583

final class ExampleUsageTests: XCTestCase {
    
    static var allTests = [
        ("testUsage", testUsage)
    ]
    
    func testUsage() {
        
        var fields : [UInt : String] = [:]
        fields[2]  = "4000010000000001"
        fields[3]  = "000000"
        fields[4]  = "000000010000"
        fields[7]  = "0101120000"
        fields[11] = "000001"
        fields[22] = "020"
        fields[24] = "200"
        fields[25] = "00"
        fields[35] = "4000010000000001=991233000123410000"
        fields[41] = "12345678"
        fields[49] = "643"
        fields[64] = "AAFFAAFFAAFFAAFF"
        
        let originalMessage : ISOMessage = ISOMessage(mti: 200, fields: fields)
        let serializedData  : Data = try! ISOMessageSerializer().serialize(message: originalMessage, scheme: SampleProcessingScheme())
        
        // print(serializedData.map { String(format: "%02X", $0) }.joined())
        // 0095020072200580208080011640000100000000010000000000000100000101120000000001002002000035343030303031303030303030303030313D39393132333330303031323334313030303031323334353637380643AAFFAAFFAAFFAAFF
        
        let deserializedMessage : ISOMessage = try! ISOMessageDeserializer().deserialize(data: serializedData, scheme: SampleProcessingScheme())
        XCTAssertEqual(deserializedMessage, originalMessage)
    }
}

/// Sample processing scheme from wikipedia article
/// https://en.wikipedia.org/wiki/ISO_8583
class SampleProcessingScheme: ISOScheme {
    
    func numberOfBytesForLength() -> UInt {
        return 2
    }
    
    func lengthFormat() -> ISONumberFormat {
        return .bcd
    }
    
    func mtiFormat() -> ISONumberFormat {
        return .bcd
    }
    
    func fieldFormat(for fieldNumber: UInt) -> ISOFieldFormat {
        
        switch fieldNumber {
        case 2:  return .llnum(lengthFormat: .bcd)    // 2   n..19     Primary account number (PAN)
        case 3:  return .numeric(length: 6)           // 3   n 6       Processing code
        case 4:  return .numeric(length: 12)          // 4   n 12      Amount, transaction
        case 5:  return .numeric(length: 12)          // 5   n 12      Amount, settlement
        case 6:  return .numeric(length: 12)          // 6   n 12      Amount, cardholder billing
        case 7:  return .numeric(length: 10)          // 7   n 10      Transmission date & time (MMDDhhmmss)
        case 8:  return .numeric(length: 8)           // 8   n 8       Amount, cardholder billing fee
        case 9:  return .numeric(length: 8)           // 9   n 8       Conversion rate, settlement
        case 10: return .numeric(length: 8)           // 10  n 8       Conversion rate, cardholder billing
        case 11: return .numeric(length: 6)           // 11  n 6       System trace audit number (STAN)
        case 12: return .numeric(length: 6)           // 12  n 6       Local transaction time (hhmmss)
        case 13: return .numeric(length: 4)           // 13  n 4       Local transaction date (MMDD)
        case 14: return .numeric(length: 4)           // 14  n 4       Expiration date
        case 15: return .numeric(length: 4)           // 15  n 4       Settlement date
        case 16: return .numeric(length: 4)           // 16  n 4       Currency conversion date
        case 17: return .numeric(length: 4)           // 17  n 4       Capture date
        case 18: return .numeric(length: 4)           // 18  n 4       Merchant type, or merchant category code
        case 19: return .numeric(length: 3)           // 19  n 3       Acquiring institution (country code)
        case 20: return .numeric(length: 3)           // 20  n 3       PAN extended (country code)
        case 21: return .numeric(length: 3)           // 21  n 3       Forwarding institution (country code)
        case 22: return .numeric(length: 3)           // 22  n 3       Point of service entry mode
        case 23: return .numeric(length: 3)           // 23  n 3       Application PAN sequence number
        case 24: return .numeric(length: 3)           // 24  n 3       Function code
        case 25: return .numeric(length: 2)           // 25  n 2       Point of service condition code
        case 26: return .numeric(length: 2)           // 26  n 2       Point of service capture code
        case 27: return .numeric(length: 1)           // 27  n 1       Authorizing identification response length
        case 28: return .alpha(length: 8)             // 28  x+n 8     Amount, transaction fee
        case 29: return .alpha(length: 8)             // 29  x+n 8     Amount, settlement fee
        case 30: return .alpha(length: 8)             // 30  x+n 8     Amount, transaction processing fee
        case 31: return .alpha(length: 8)             // 31  x+n 8     Amount, settlement processing fee
        case 32: return .llnum(lengthFormat: .bcd)    // 32  n..11     Acquiring institution identification code
        case 33: return .llnum(lengthFormat: .bcd)    // 33  n..11     Forwarding institution identification code
        case 34: return .llvar(lengthFormat: .bcd)    // 34  ns..28    Primary account number, extended
        case 35: return .llvar(lengthFormat: .bcd)    // 35  z..37     Track 2 data
        case 36: return .lllnum(lengthFormat: .bcd)   // 36  n..104    Track 3 data
        case 37: return .alpha(length: 12)            // 37  an 12     Retrieval reference number
        case 38: return .alpha(length: 6)             // 38  an 6      Authorization identification response
        case 39: return .alpha(length: 2)             // 39  an 2      Response code
        case 40: return .alpha(length: 3)             // 40  an 3      Service restriction code
        case 41: return .alpha(length: 8)             // 41  ans 8     Card acceptor terminal identification
        case 42: return .alpha(length: 15)            // 42  ans 15    Card acceptor identification code
        case 43: return .alpha(length: 40)            // 43  ans 40    Card acceptor name/location (1–23 street address, –36 city, –38 state, 39–40 country)
        case 44: return .llvar(lengthFormat: .bcd)    // 44  an..25    Additional response data
        case 45: return .llvar(lengthFormat: .bcd)    // 45  an..76    Track 1 data
        case 46: return .lllvar(lengthFormat: .bcd)   // 46  an..999   Additional data (ISO)
        case 47: return .lllvar(lengthFormat: .bcd)   // 47  an..999   Additional data (national)
        case 48: return .lllvar(lengthFormat: .bcd)   // 48  an..999   Additional data (private)
        case 49: return .numeric(length: 3)           // 49  n 3       Currency code, transaction
        case 50: return .numeric(length: 3)           // 50  n 3       Currency code, settlement
        case 51: return .numeric(length: 3)           // 51  n 3       Currency code, cardholder billing
        case 52: return .binary(length: 8)            // 52  b 8       Personal identification number data
        case 53: return .numeric(length: 16)          // 53  n 16      Security related control information
        case 54: return .lllvar(lengthFormat: .bcd)   // 54  an..120   Additional amounts
        case 55: return .lllvar(lengthFormat: .bcd)   // 55  ans..999  ICC data – EMV having multiple tags
        case 56: return .lllvar(lengthFormat: .bcd)   // 56  ans..999  Reserved (ISO)
        case 57: return .lllvar(lengthFormat: .bcd)   // 57  ans..999  Reserved (national)
        case 58: return .lllvar(lengthFormat: .bcd)   // 58  ans..999
        case 59: return .lllvar(lengthFormat: .bcd)   // 59  ans..999
        case 60: return .lllvar(lengthFormat: .bcd)   // 60  ans..999  Reserved (national)
        case 61: return .lllvar(lengthFormat: .bcd)   // 61  ans..999  Reserved (private)
        case 62: return .lllvar(lengthFormat: .bcd)   // 62  ans..999  Reserved (private)
        case 63: return .lllvar(lengthFormat: .bcd)   // 63  ans..999  Reserved (private)
        case 64: return .binary(length: 8)            // 64  b 8       Message authentication code (MAC)
        default:
            return .undefined
        }
    }
}
