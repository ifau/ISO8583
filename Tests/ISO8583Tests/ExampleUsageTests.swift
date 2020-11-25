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
        fields[3]  = "000000"
        fields[4]  = "000000010000"
        fields[7]  = "0101120000"
        fields[11] = "000001"
        fields[22] = "021"
        fields[24] = "200"
        fields[25] = "00"
        fields[35] = "4000010000000001=991233000123410000"
        fields[41] = "12345678"
        fields[49] = "643"
        fields[52] = "AABBCCDDEEFFFFFF"
        
        let originalMessage : ISOMessage = ISOMessage(mti: 200, fields: fields)
        
        let serializedSampleData : Data = try! ISOMessageSerializer().serialize(message: originalMessage, scheme: SampleProcessingScheme())
        let deserializedSampleMessage : ISOMessage = try! ISOMessageDeserializer().deserialize(data: serializedSampleData, scheme: SampleProcessingScheme())
        XCTAssertEqual(deserializedSampleMessage, originalMessage)
        
        let serializedSmartVistaData : Data = try! ISOMessageSerializer().serialize(message: originalMessage, scheme: SmartVistaScheme())
        let deserializedSmartVistaMessage : ISOMessage = try! ISOMessageDeserializer().deserialize(data: serializedSmartVistaData, scheme: SmartVistaScheme())
        XCTAssertEqual(deserializedSmartVistaMessage, originalMessage)
        
        let serializedOpenWayData : Data = try! ISOMessageSerializer().serialize(message: originalMessage, scheme: OpenWayScheme())
        let deserializedOpenWayMessage : ISOMessage = try! ISOMessageDeserializer().deserialize(data: serializedOpenWayData, scheme: OpenWayScheme())
        XCTAssertEqual(deserializedOpenWayMessage, originalMessage)
        
        /*
        let hexdump = { (data: Data) -> String in
            
            let inputPipe = Pipe()
            let outputPipe = Pipe()
            let hexdump = Process()
            hexdump.launchPath = "/usr/bin/hexdump"
            hexdump.arguments = ["-C"]
            hexdump.standardInput = inputPipe
            hexdump.standardOutput = outputPipe
            hexdump.launch()
            
            inputPipe.fileHandleForWriting.write(data)
            inputPipe.fileHandleForWriting.closeFile()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            return output ?? ""
        }
        
        print(hexdump(serializedSampleData))
        
        00000000  00 86 02 00 32 20 05 80  20 80 90 00 00 00 00 00  |....2 .. .......|
        00000010  00 00 01 00 00 01 01 12  00 00 00 00 01 00 21 02  |..............!.|
        00000020  00 00 35 34 30 30 30 30  31 30 30 30 30 30 30 30  |..54000010000000|
        00000030  30 30 31 3d 39 39 31 32  33 33 30 30 30 31 32 33  |001=991233000123|
        00000040  34 31 30 30 30 30 31 32  33 34 35 36 37 38 06 43  |41000012345678.C|
        00000050  aa bb cc dd ee ff ff ff                           |........|
        
        print(hexdump(serializedSmartVistaData))
        
        00000000  30 31 30 39 30 32 30 30  32 20 05 80 20 80 90 00  |010902002 .. ...|
        00000010  30 30 30 30 30 30 30 30  30 30 30 30 30 31 30 30  |0000000000000100|
        00000020  30 30 30 31 30 31 31 32  30 30 30 30 30 30 30 30  |0001011200000000|
        00000030  30 31 30 32 31 32 30 30  30 30 33 35 34 30 30 30  |0102120000354000|
        00000040  30 31 30 30 30 30 30 30  30 30 30 31 3d 39 39 31  |010000000001=991|
        00000050  32 33 33 30 30 30 31 32  33 34 31 30 30 30 30 31  |2330001234100001|
        00000060  32 33 34 35 36 37 38 06  43 aa bb cc dd ee ff ff  |2345678.C.......|
        00000070  ff                                                |.|
        
        print(hexdump(serializedOpenWayData))
        
        00000000  00 86 02 00 32 20 05 80  20 80 90 00 00 00 00 00  |....2 .. .......|
        00000010  00 00 01 00 00 01 01 12  00 00 00 00 01 00 21 02  |..............!.|
        00000020  00 00 35 34 30 30 30 30  31 30 30 30 30 30 30 30  |..54000010000000|
        00000030  30 30 31 3d 39 39 31 32  33 33 30 30 30 31 32 33  |001=991233000123|
        00000040  34 31 30 30 30 30 31 32  33 34 35 36 37 38 06 43  |41000012345678.C|
        00000050  aa bb cc dd ee ff ff ff                           |........|
        */
    }
}

/// SmartVista Processing Scheme
/// Source: https://github.com/juks/iso-8583-socket-queue/blob/master/lib/iso8583/lib/packager/smartVista.js
class SmartVistaScheme: ISOScheme {
    func numberOfBytesForLength() -> UInt {
        return 4
    }

    func lengthFormat() -> ISONumberFormat {
        return .ascii
    }

    func mtiFormat() -> ISONumberFormat {
        return .ascii
    }

    func fieldFormat(for fieldNumber: UInt) -> ISOFieldFormat {
        switch fieldNumber {
        case 2: return .llvar(lengthFormat: .ascii, valueFormat: [.n])      // Primary Account Number
        case 3: return .alpha(length: 6, valueFormat: [.n])                 // Processing Code
        case 4: return .alpha(length: 12, valueFormat: [.n])                // Amount, Transaction
        case 5: return .alpha(length: 12, valueFormat: [.n])                // Amount, Settlement
        case 6: return .alpha(length: 12, valueFormat: [.n])                // Amount, Cardholder Billing
        case 7: return .alpha(length: 10, valueFormat: [.n])                // Transmission Date and Time
        case 8: return .alpha(length: 8, valueFormat: [.n])                 // Amount, Cardholder Billing Fee
        case 9: return .alpha(length: 8, valueFormat: [.n])                 // Conversion Rate, Settlement
        case 10: return .alpha(length: 8, valueFormat: [.n])                // Conversion Rate, Cardholder Billing
        case 11: return .alpha(length: 6, valueFormat: [.n])                // System Trace Audit Number
        case 12: return .alpha(length: 12, valueFormat: [.n])               // Time, Local Transaction
        case 13: return .alpha(length: 4, valueFormat: [.n])                // Date, Local Transaction
        case 14: return .alpha(length: 6, valueFormat: [.n])                // Date, Expiration
        case 15: return .alpha(length: 4, valueFormat: [.n])                // Date, Settlement
        case 22: return .alpha(length: 3, valueFormat: [.n])                // Pos Entry Mode
        case 24: return .alpha(length: 3, valueFormat: [.n])                // Function Code
        case 25: return .alpha(length: 2, valueFormat: [.n])                // Pos Condition Code
        case 32: return .llvar(lengthFormat: .ascii, valueFormat: [.n])     // Acquiring Institution Ident Code
        case 35: return .llvar(lengthFormat: .ascii, valueFormat: [.z])     // Track 2 Data
        case 37: return .alpha(length: 12, valueFormat: [.a, .n, .s])       // Retrieval Reference Number
        case 38: return .alpha(length: 6, valueFormat: [.a, .n, .s])        // Approval code
        case 39: return .alpha(length: 3, valueFormat: [.n])                // Response code
        case 41: return .alpha(length: 8, valueFormat: [.n])                // Card Acceptor Terminal Identification
        case 42: return .alpha(length: 15, valueFormat: [.a, .n, .s])       // Merchant Id
        case 46: return .llvar(lengthFormat: .ascii, valueFormat: [.a, .n]) // Amount, Fees
        case 49: return .numeric(length: 3)                                 // Currency code, transaction
        case 52: return .binary(length: 8)                                  // Personal Identification Data
        case 54: return .llvar(lengthFormat: .ascii, valueFormat: [.a, .n]) // Additional amounts
        case 55: return .lllbin(lengthFormat: .bcd)                         // EMV Data
        case 62: return .llvar(lengthFormat: .ascii, valueFormat: [.a, .n]) // Customer Defined Response
        case 64: return .binary(length: 8)                                  // MAC
        default:
            return .undefined
        }
    }
}

/// OpenWay Processing Scheme
/// Source: https://github.com/juks/iso-8583-socket-queue/blob/master/lib/iso8583/lib/packager/openWay.js
class OpenWayScheme: ISOScheme {
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
        case 2: return .llnum(lengthFormat: .bcd)                             // Primary Account Number
        case 3: return .numeric(length: 6)                                    // Processing Code
        case 4: return .numeric(length: 12)                                   // Amount, Transaction
        case 5: return .numeric(length: 12)                                   // Amount, Settlement
        case 6: return .numeric(length: 12)                                   // Amount, Cardholder Billing
        case 7: return .numeric(length: 10)                                   // Transmission Date and Time
        case 8: return .numeric(length: 8)                                    // Amount, Cardholder Billing Fee
        case 9: return .numeric(length: 8)                                    // Conversion Rate, Settlement
        case 10: return .numeric(length: 8)                                   // Conversion Rate, Cardholder Billing
        case 11: return .numeric(length: 6)                                   // System Trace Audit Number
        case 12: return .numeric(length: 12)                                  // Processing Time
        case 13: return .numeric(length: 4)                                   // Processing Date
        case 14: return .numeric(length: 4)                                   // Date, Expiration
        case 22: return .numeric(length: 3)                                   // Pos Entry Mode
        case 23: return .numeric(length: 3)                                   // Card Sequence Number
        case 24: return .numeric(length: 3)                                   // Function Code
        case 25: return .numeric(length: 2)                                   // Pos Condition Code
        case 31: return .llbin(lengthFormat: .bcd)                            // Security Additional Data – private
        case 32: return .llnum(lengthFormat: .bcd)                            // Acquiring Institution ID
        case 33: return .llnum(lengthFormat: .bcd)                            // Forwarding Institution ID
        case 34: return .llvar(lengthFormat: .bcd, valueFormat: [.z])         // PAN extended
        case 35: return .llvar(lengthFormat: .bcd, valueFormat: [.z])         // Track 2 Data
        case 36: return .llvar(lengthFormat: .bcd, valueFormat: [.z])         // Track 3 Data
        case 37: return .alpha(length: 12, valueFormat: [.a, .n, .s])         // Retrieval Reference Number
        case 38: return .alpha(length: 6, valueFormat: [.a, .n, .s])          // Authorisation Identification Response
        case 39: return .alpha(length: 3, valueFormat: [.n])                  // Response code
        case 40: return .numeric(length: 1)                                   // Service Restriction Code
        case 41: return .alpha(length: 8, valueFormat: [.a, .n, .s])          // Card Acceptor Terminal Identification
        case 42: return .alpha(length: 15, valueFormat: [.a, .n, .s])         // Card Acceptor ID
        case 43: return .alpha(length: 40, valueFormat: [.a, .n, .s])         // Card Acceptor Name
        case 44: return .llvar(lengthFormat: .bcd, valueFormat: [.a, .n, .s]) // Additional Response Data
        case 45: return .llvar(lengthFormat: .bcd, valueFormat: [.z])         // Track 1 Data
        case 46: return .lllvar(lengthFormat: .bcd, valueFormat: [.a, .n])    // Amount, Fees
        case 47: return .lllvar(lengthFormat: .bcd, valueFormat: [.a, .n])    // Additional Data
        case 48: return .lllvar(lengthFormat: .bcd, valueFormat: [.a, .n])    // Additional Data
        case 49: return .numeric(length: 3)                                   // Currency Code, Transaction
        case 50: return .numeric(length: 3)                                   // Currency Code, Settlement
        case 51: return .numeric(length: 3)                                   // Currency Code, Cardholder billing
        case 52: return .binary(length: 8)                                    // Personal Identification Data
        case 53: return .binary(length: 8)                                    // Security Related Control Information
        case 54: return .lllvar(lengthFormat: .bcd, valueFormat: [.a, .n])    // Additional amounts
        case 55: return .lllbin(lengthFormat: .bcd)                           // EMV Data
        case 56: return .llbin(lengthFormat: .bcd)                            // Original Data Elements
        case 57: return .numeric(length: 2)                                   // Authorisation Life Cycle Code
        case 58: return .llnum(lengthFormat: .bcd)                            // Authorizing Agent Institution ID
        case 59: return .llvar(lengthFormat: .bcd, valueFormat: [.a, .n])     // Additional Data
        case 60: return .llvar(lengthFormat: .bcd, valueFormat: [.a, .n])     // Original Data Elements
        case 61: return .llvar(lengthFormat: .bcd, valueFormat: [.a, .n])     // Reserved
        case 62: return .llvar(lengthFormat: .bcd, valueFormat: [.a, .n])     // Reserved
        case 63: return .llvar(lengthFormat: .bcd, valueFormat: [.a, .n])     // Additional Data
        case 64: return .binary(length: 4)                                    // MAC
        default:
            return .undefined
        }
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
        case 2:  return .llnum(lengthFormat: .bcd)                             // 2   n..19     Primary account number (PAN)
        case 3:  return .numeric(length: 6)                                    // 3   n 6       Processing code
        case 4:  return .numeric(length: 12)                                   // 4   n 12      Amount, transaction
        case 5:  return .numeric(length: 12)                                   // 5   n 12      Amount, settlement
        case 6:  return .numeric(length: 12)                                   // 6   n 12      Amount, cardholder billing
        case 7:  return .numeric(length: 10)                                   // 7   n 10      Transmission date & time (MMDDhhmmss)
        case 8:  return .numeric(length: 8)                                    // 8   n 8       Amount, cardholder billing fee
        case 9:  return .numeric(length: 8)                                    // 9   n 8       Conversion rate, settlement
        case 10: return .numeric(length: 8)                                    // 10  n 8       Conversion rate, cardholder billing
        case 11: return .numeric(length: 6)                                    // 11  n 6       System trace audit number (STAN)
        case 12: return .numeric(length: 6)                                    // 12  n 6       Local transaction time (hhmmss)
        case 13: return .numeric(length: 4)                                    // 13  n 4       Local transaction date (MMDD)
        case 14: return .numeric(length: 4)                                    // 14  n 4       Expiration date
        case 15: return .numeric(length: 4)                                    // 15  n 4       Settlement date
        case 16: return .numeric(length: 4)                                    // 16  n 4       Currency conversion date
        case 17: return .numeric(length: 4)                                    // 17  n 4       Capture date
        case 18: return .numeric(length: 4)                                    // 18  n 4       Merchant type, or merchant category code
        case 19: return .numeric(length: 3)                                    // 19  n 3       Acquiring institution (country code)
        case 20: return .numeric(length: 3)                                    // 20  n 3       PAN extended (country code)
        case 21: return .numeric(length: 3)                                    // 21  n 3       Forwarding institution (country code)
        case 22: return .numeric(length: 3)                                    // 22  n 3       Point of service entry mode
        case 23: return .numeric(length: 3)                                    // 23  n 3       Application PAN sequence number
        case 24: return .numeric(length: 3)                                    // 24  n 3       Function code
        case 25: return .numeric(length: 2)                                    // 25  n 2       Point of service condition code
        case 26: return .numeric(length: 2)                                    // 26  n 2       Point of service capture code
        case 27: return .numeric(length: 1)                                    // 27  n 1       Authorizing identification response length
        case 28: return .alpha(length: 8, valueFormat:[.x, .n])                // 28  x+n 8     Amount, transaction fee
        case 29: return .alpha(length: 8, valueFormat:[.x, .n])                // 29  x+n 8     Amount, settlement fee
        case 30: return .alpha(length: 8, valueFormat:[.x, .n])                // 30  x+n 8     Amount, transaction processing fee
        case 31: return .alpha(length: 8, valueFormat:[.x, .n])                // 31  x+n 8     Amount, settlement processing fee
        case 32: return .llnum(lengthFormat: .bcd)                             // 32  n..11     Acquiring institution identification code
        case 33: return .llnum(lengthFormat: .bcd)                             // 33  n..11     Forwarding institution identification code
        case 34: return .llvar(lengthFormat: .bcd, valueFormat:[.n, .s])       // 34  ns..28    Primary account number, extended
        case 35: return .llvar(lengthFormat: .bcd, valueFormat:[.z])           // 35  z..37     Track 2 data
        case 36: return .lllnum(lengthFormat: .bcd)                            // 36  n..104    Track 3 data
        case 37: return .alpha(length: 12, valueFormat:[.a, .n])               // 37  an 12     Retrieval reference number
        case 38: return .alpha(length: 6, valueFormat:[.a, .n])                // 38  an 6      Authorization identification response
        case 39: return .alpha(length: 2, valueFormat:[.a, .n])                // 39  an 2      Response code
        case 40: return .alpha(length: 3, valueFormat:[.a, .n])                // 40  an 3      Service restriction code
        case 41: return .alpha(length: 8, valueFormat:[.a, .n, .s])            // 41  ans 8     Card acceptor terminal identification
        case 42: return .alpha(length: 15, valueFormat:[.a, .n, .s])           // 42  ans 15    Card acceptor identification code
        case 43: return .alpha(length: 40, valueFormat:[.a, .n, .s])           // 43  ans 40    Card acceptor name/location (1–23 street address, –36 city, –38 state, 39–40 country)
        case 44: return .llvar(lengthFormat: .bcd, valueFormat:[.a, .n])       // 44  an..25    Additional response data
        case 45: return .llvar(lengthFormat: .bcd, valueFormat:[.a, .n])       // 45  an..76    Track 1 data
        case 46: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n])      // 46  an..999   Additional data (ISO)
        case 47: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n])      // 47  an..999   Additional data (national)
        case 48: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n])      // 48  an..999   Additional data (private)
        case 49: return .numeric(length: 3)                                    // 49  n 3       Currency code, transaction
        case 50: return .numeric(length: 3)                                    // 50  n 3       Currency code, settlement
        case 51: return .numeric(length: 3)                                    // 51  n 3       Currency code, cardholder billing
        case 52: return .binary(length: 8)                                     // 52  b 8       Personal identification number data
        case 53: return .numeric(length: 16)                                   // 53  n 16      Security related control information
        case 54: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n])      // 54  an..120   Additional amounts
        case 55: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 55  ans..999  ICC data – EMV having multiple tags
        case 56: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 56  ans..999  Reserved (ISO)
        case 57: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 57  ans..999  Reserved (national)
        case 58: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 58  ans..999
        case 59: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 59  ans..999
        case 60: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 60  ans..999  Reserved (national)
        case 61: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 61  ans..999  Reserved (private)
        case 62: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 62  ans..999  Reserved (private)
        case 63: return .lllvar(lengthFormat: .bcd, valueFormat:[.a, .n, .s])  // 63  ans..999  Reserved (private)
        case 64: return .binary(length: 8)                                     // 64  b 8       Message authentication code (MAC)
        default:
            return .undefined
        }
    }
}
