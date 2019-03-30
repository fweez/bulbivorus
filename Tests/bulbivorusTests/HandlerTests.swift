//
//  HandlerTests.swift
//  bulbivorusTests
//
//  Created by Ryan Forsythe on 3/30/19.
//

import XCTest
@testable import bulbivorusCore

class HandlerTests: XCTestCase {
    enum HandlerTestsError: Error {
        case testError
    }
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func buildDataHandlerAndExpectation() -> (HandlerDataHandler, XCTestExpectation) {
        let handlerWrittenExpectation = expectation(description: "handler write happened")
        let dataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
            handlerWrittenExpectation.fulfill()
            writeComplete(data.count)
        }
        return (dataHandler, handlerWrittenExpectation)
    }
    
    func buildCompletionAndExpectation() -> (HandlerCompletion, XCTestExpectation) {
        let handlerCompletionExpectation = expectation(description: "handler completion happened")
        let completion = {
            handlerCompletionExpectation.fulfill()
        }
        return (completion, handlerCompletionExpectation)
    }

    func testErrorHandler() {
        let (dataHandler, handlerWrittenExpectation) = buildDataHandlerAndExpectation()
        let (completion, handlerCompletionExpectation) = buildCompletionAndExpectation()
        _ = ErrorHandler(request: "", error: HandlerTestsError.testError, dataHandler: dataHandler, handlerCompletion: completion)
        wait(for: [handlerWrittenExpectation, handlerCompletionExpectation], timeout: 1)
    }
    
    func testFileHandlerThrowsCouldNotList() {
        let cfg = FileHandlerConfiguration(root: ".")

        do {
            _ = try FileHandler(request: "/", configuration: cfg, dataHandler: { (_,_) in return }, handlerCompletion: { return })
            XCTFail("Should have thrown in init")
        } catch {
            guard let fherr = error as? FileHandler.FileError else {
                XCTFail("Error should have been a file handler file error, was \(String(reflecting: error))")
                return
            }
            XCTAssert(fherr == FileHandler.FileError.couldNotListDirectory, "Error should have been could not list directory")
        }
    }
    
    func testFileHandlerThrowsFileDNE() {
        let cfg = FileHandlerConfiguration(root: ".")
        
        do {
            _ = try FileHandler(request: "/afile", configuration: cfg, dataHandler: { (_,_) in return }, handlerCompletion: { return })
            XCTFail("Should have thrown in init")
        } catch {
            guard let fherr = error as? FileHandler.FileError else {
                XCTFail("Error should have been a file handler file error, was \(String(reflecting: error))")
                return
            }
            XCTAssert(fherr == FileHandler.FileError.fileDoesNotExist, "Error should have been file does not exist")
        }
    }
}
