import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ExampleUsageTests.allTests),
        testCase(ISOMessageSerializerTests.allTests),
        testCase(ISOMessageDeserializerTests.allTests)
    ]
}
#endif
