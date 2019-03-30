import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(bulbivorusTests.allTests),
        testCase(ConnectionTests.allTests),
        testCase(RouterTests.allTests),
    ]
}
#endif
