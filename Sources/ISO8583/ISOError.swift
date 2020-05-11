//
//  ISOError.swift
//  ISO8583
//
//  Created by Evgeny Seliverstov on 05/05/2020.
//

import Foundation

public enum ISOError : Error {
    
    /// Serialize message failed
    case serializeMessageFailed(reason: SerializeMessageFailureReason)
    /// Deserialize message failed
    case deserializeMessageFailed(reason: DeserializeMessageFailureReason)
    
    /// Underlying reason the `.serializeMessageFailed` error occurred
    public enum SerializeMessageFailureReason {
        
        /// Length is more than declared length format can encode
        case lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength: UInt, actualLength: UInt)
        /// MTI declared in `mti` property of message is incorrect
        case messageContainIncorrectMTI(_ incorrectMTI: UInt)
        /// Message fields with provided field numbers are prohibited
        case messageContainIncorrectFieldNumbers(_ incorrectFieldNumbers: [UInt])
        /// Length of field is not equal to length declared for this field in `ISOScheme` protocol
        case fieldLengthIsNotEqualToDeclaredLength(fieldNumber: UInt, declaredLength: UInt, actualLength: UInt)
        /// Value of field contain unacceptable characters
        case fieldValueIsNotConformToDeclaredFormat(fieldNumber: UInt, declaredFormat: ISOStringFormat, actualValue: String)
        /// Length of field value is more than declared field format can encode
        case fieldValueIsMoreThanMaximumLengthForDeclaredFormat(fieldNumber: UInt, maximumLength: UInt, actualLength: UInt)
        /// Field format is undefined
        case fieldFormatIsUndefined(fieldNumber: UInt)
    }
    
    /// Underlying reason the `.deserializeMessageFailed` error occurred
    public enum DeserializeMessageFailureReason {
        
        /// Provided data is less than declared number of bytes for message length
        case notEnoughDataForDecodeMessageLength
        /// Provided data is less than length wich was decoded from it
        case messageIsLessThanDecodedLength(decodedLength: UInt, actualLength: UInt)
        /// Value of length contain unacceptable bytes
        case lengthIsNotConformToDeclaredFormat(declaredFormat: String, actualValue: String)
        /// Provided data is lnot enough for decode mti
        case notEnoughDataForDecodeMTI
        /// Provided data is lnot enough for decode primary bitmap
        case notEnoughDataForDecodePrimaryBitmap
        /// Provided data is lnot enough for decode secondary bitmap
        case notEnoughDataForDecodeSecondaryBitmap
        /// Length of field is not equal to length declared for this field in `ISOScheme` protocol
        case fieldLengthIsNotEqualToDeclaredLength(fieldNumber: UInt, declaredLength: UInt, actualLength: UInt)
        /// Value of field contain unacceptable characters
        case fieldValueIsNotConformToDeclaredFormat(fieldNumber: UInt, declaredFormat: ISOStringFormat, actualValue: String)
        /// Provided data is lnot enough for decode field length
        case notEnoughDataForDecodeFieldLength(fieldNumber: UInt)
        /// Value of field is less than length decoded from message
        case fieldValueIsLessThanDecodedLength(fieldNumber: UInt, decodedLength: UInt, actualLength: UInt)
        /// Field format is undefined
        case fieldFormatIsUndefined(fieldNumber: UInt)
    }
}

extension ISOError.SerializeMessageFailureReason {
    
    var localizedDescription: String {
        switch self {
        case let .lengthIsMoreThanMaximumLengthForDeclaredFormat(maximumLength, actualLength):
            return "Length is more than declared length format can encode (maximum length: \(maximumLength), actual length: \(actualLength))"
        case let .messageContainIncorrectMTI(incorrectMTI):
            return "Message could not be serialized because mti \(incorrectMTI) is incorrect"
        case let .messageContainIncorrectFieldNumbers(incorrectFieldNumbers):
            return "Message could not be serialized because field numbers \(incorrectFieldNumbers) are prohibited"
        case let .fieldLengthIsNotEqualToDeclaredLength(fieldNumber, declaredLength, actualLength):
            return "Message could not be serialized because length of field \(fieldNumber) is not equal to declared length (declared: \(declaredLength), actual: \(actualLength))"
        case let .fieldValueIsNotConformToDeclaredFormat(fieldNumber, declaredFormat, actualValue):
            return "Message could not be serialized because value format of field \(fieldNumber) is not confirm to declared format (declared format: \(declaredFormat), actual value: \(actualValue))"
        case let .fieldValueIsMoreThanMaximumLengthForDeclaredFormat(fieldNumber, maximumLength, actualLength):
            return "Message could not be serialized because value of field \(fieldNumber) is more than maximum length of declared format (maximum length: \(maximumLength), actual length: \(actualLength))"
        case let .fieldFormatIsUndefined(fieldNumber):
            return "Message could not be serialized because field format for field \(fieldNumber) is undefined"
        }
    }
}

extension ISOError.DeserializeMessageFailureReason {
    
    var localizedDescription: String {
        switch self {
        case .notEnoughDataForDecodeMessageLength:
            return "Message could not be deserialized because there is not enough data (could not decode message length)"
        case let .messageIsLessThanDecodedLength(decodedLength, actualLength):
            return "Message could not be deserialized because message is less than decoded length (decoded length: \(decodedLength), actual length: \(actualLength))"
        case let .lengthIsNotConformToDeclaredFormat(declaredFormat, actualValue):
            return "Message could not be deserialized because length format is not confirm to declared format (declared format: \(declaredFormat), actual value: \(actualValue))"
        case .notEnoughDataForDecodeMTI:
            return "Message could not be deserialized because there is not enough data (could not decode mti)"
        case .notEnoughDataForDecodePrimaryBitmap:
            return "Message could not be deserialized because there is not enough data (could not decode primary bitmap)"
        case .notEnoughDataForDecodeSecondaryBitmap:
            return "Message could not be deserialized because there is not enough data (could not decode secondary bitmap)"
        case let .fieldLengthIsNotEqualToDeclaredLength(fieldNumber, declaredLength, actualLength):
            return "Message could not be deserialized because length of field \(fieldNumber) is not equal to declared length (declared: \(declaredLength), actual: \(actualLength))"
        case let .fieldValueIsNotConformToDeclaredFormat(fieldNumber, declaredFormat, actualValue):
            return "Message could not be deserialized because value format of field \(fieldNumber) is not confirm to declared format (declared format: \(declaredFormat), actual value: \(actualValue))"
        case let .notEnoughDataForDecodeFieldLength(fieldNumber):
            return "Message could not be deserialized because there is not enough data (could not decode length of field \(fieldNumber))"
        case let .fieldValueIsLessThanDecodedLength(fieldNumber, decodedLength, actualLength):
            return "Message could not be deserialized because length of field \(fieldNumber) is less than decoded length (decoded length: \(decodedLength), actualLength: \(actualLength))"
        case let .fieldFormatIsUndefined(fieldNumber):
            return "Message could not be deserialized because field format for field \(fieldNumber) is undefined"
        }
    }
}
