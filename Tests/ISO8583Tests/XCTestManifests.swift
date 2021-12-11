import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ExampleUsageTests.allTests),
        testCase(AlphaFieldEncoderTests.allTests),
        testCase(BinaryFieldEncoderTests.allTests),
        testCase(BitmapEncoderTests.allTests),
        testCase(LengthEncoderTests.allTests),
        testCase(MTIEncoderTests.allTests),
        testCase(NumericFieldEncoderTests.allTests),
        testCase(VariableAlphaFieldEncoderTests.allTests),
        testCase(VariableBinaryFieldEncoderTests.allTests),
        testCase(VariableNumericFieldEncoderTests.allTests)
    ]
}
#endif
