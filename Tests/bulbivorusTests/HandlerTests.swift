//
//  HandlerTests.swift
//  bulbivorusTests
//
//  Created by Ryan Forsythe on 3/30/19.
//

import XCTest
@testable import bulbivorusCore

class HandlerTests: XCTestCase {
    static var allTests = [
        ("testErrorHandler", testErrorHandler),
        ("testFileHandlerThrowsCouldNotList", testFileHandlerThrowsCouldNotList),
        ("testFileHandlerThrowsFileDNE", testFileHandlerThrowsFileDNE),
        ("testFileHandlerSendsRootGophermap", testFileHandlerSendsRootGophermap),
    ]
    enum HandlerTestsError: Error {
        case testError
    }
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        //removeTestGopherhole()
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
    
    func createDir(_ path: String) {
        guard FileManager.default.fileExists(atPath: path) == false else { return }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Unexpected error while creating test directory at \(path): \(error)")
        }
    }
    
    func createFile(contents: String, path: String) {
        guard FileManager.default.fileExists(atPath: path) == false else { return }
        do {
            try contents.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Unexpected error while creating file at \(path): \(error)")
        }
    }
    
    let testRootDir = "/tmp/bulbivorus-test-root"

    /// Creates a directory structure and test files in a gopherhole
    /// In /tmp/bulbivorus-test-root/:
        /// ./gophermap -- two line gophermap
        /// ./no-gophermap/ -- a subdirectory with no gophermap
        /// ./no-gophermap/test.txt -- just some text
        /// ./with-gophermap/ -- a subdir with a gophermap
        /// ./with-gophermap/gophermap -- a one line gophermap
    func createTestGopherhole() {
        removeTestGopherhole()
        createDir(testRootDir)
        
        let rootMap = """
        iThis is the root of the test gopherhole
        1Generated Gophermap\tno-gophermap
        1Composed Gopheramp\twith-gophermap
        """
        let rootMapPath = testRootDir + "/gophermap"
        createFile(contents: rootMap, path: rootMapPath)
        
        let noMapDir = testRootDir + "/no-gophermap"
        createDir(noMapDir)
        
        let noMapFile = "Here is a test file"
        let noMapFilePath = noMapDir + "/test.txt"
        createFile(contents: noMapFile, path: noMapFilePath)
        
        let mapDir = testRootDir + "/with-gophermap"
        createDir(mapDir)
        
        let mapDirMap = """
        iThis is a subdir in the test gopherhole
        """
        let mapDirMapPath = mapDir + "/gophermap"
        createFile(contents: mapDirMap, path: mapDirMapPath)
    }
    
    func removeTestGopherhole() {
        guard FileManager.default.fileExists(atPath: testRootDir) else { return }
        do {
            try FileManager.default.removeItem(atPath: testRootDir)
        } catch {
            XCTFail("Unexpected error while removing test gopherhole at \(testRootDir): \(error)")
        }
    }
    
    func testFileHandlerSendsRootGophermap() {
        createTestGopherhole()
        //TODO
    }
}
