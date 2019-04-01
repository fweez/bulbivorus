import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ConnectionTests.allTests),
        testCase(RouterTests.allTests),
        testCase(HandlerTests.allTests),
    ]
}
#endif
