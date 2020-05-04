import XCTest

import ISO8583Tests

var tests = [XCTestCaseEntry]()
tests += ISO8583Tests.allTests()
XCTMain(tests)
