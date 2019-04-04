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
        ("testFileHandlerSendsAuthoredSubdirGophermap", testFileHandlerSendsAuthoredSubdirGophermap),
        ("testFileHandlerSendsGeneratedSubdirGophermap", testFileHandlerSendsGeneratedSubdirGophermap),
        ("testFileHandlerSendsTextFilesProperly", testFileHandlerSendsTextFilesProperly),
        ("testFileHandlerSendsDataFilesProperly", testFileHandlerSendsDataFilesProperly),
        ("testTraverseOutOfGopherholeAndReadDir", testTraverseOutOfGopherholeAndReadDir),
        ("testTraverseOutOfHoleAndReadFile", testTraverseOutOfHoleAndReadFile)
    ]
    enum HandlerTestsError: Error {
        case testError
    }
    
    override func setUp() {
        createTestGopherhole()
    }
    
    override func tearDown() {
       removeTestGopherhole()
    }
    
    /// Creates a directory at the given path, with intermediate directories, if the dir doesn't exist; XCTFail's on any throw
    func createDir(_ path: String) {
        guard FileManager.default.fileExists(atPath: path) == false else { return }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Unexpected error while creating test directory at \(path): \(error)")
        }
    }
    
    /// Creates a file at the given path if it doesn't exist; XCTFail's on any throw
    ///
    /// - Parameters:
    ///   - contents: File contents
    ///   - path: Path to file
    func createFile(contents: String, path: String) {
        guard FileManager.default.fileExists(atPath: path) == false else { return }
        do {
            try contents.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Unexpected error while creating file at \(path): \(error)")
        }
    }
    
    func createBinaryFile(contents: Data, path: String) {
        guard FileManager.default.fileExists(atPath: path) == false else { return }
        do {
            let u = URL(fileURLWithPath: path)
            try contents.write(to: u)
        } catch {
            XCTFail("Unexpected error while creating file at \(path): \(error)")
        }
    }
    
    /// Root directory of the test gopherhole created in createTestGopherhole()
    let testRootDir = "/tmp/bulbivorus-test-root"
    let rootGophermap = """
        iThis is the root of the test gopherhole
        1Generated Gophermap\tno-gophermap/
        1Composed Gophermap\twith-gophermap/
        """
    let subdirGophermap = """
        iThis is a subdir in the test gopherhole
        """
    let textFileContents = "Here is a test file"
    let imageData = "Corrupt image data".data(using: .utf8)!
    /// Creates a directory structure and test files in a gopherhole
    ///
    /// In /tmp/bulbivorus-test-root/:
    /// ./gophermap -- three line gophermap
    /// ./no-gophermap/ -- a subdirectory with no gophermap
    /// ./no-gophermap/test.txt -- just some text
    /// ./no-gophermap/test.md -- just some (theoretically Markdown) text
    /// ./no-gophermap/test.gif -- a corrupt gif
    /// ./no-gophermap/test.png -- ...png
    /// ./no-gophermap/test.jpg -- ...jpg
    /// ./no-gophermap/test.jpeg -- ...jpg
    /// ./no-gophermap/test.binary -- unrecognized suffixes are transferred as binary
    /// ./with-gophermap/ -- a subdir with a gophermap
    /// ./with-gophermap/gophermap -- a one line gophermap
    func createTestGopherhole() {
        removeTestGopherhole()
        createDir(testRootDir)
        
        let rootMapPath = testRootDir + "/gophermap"
        createFile(contents: rootGophermap, path: rootMapPath)
        
        let noMapDir = testRootDir + "/no-gophermap"
        createDir(noMapDir)
        
        let noMapTextFilePath = noMapDir + "/test.txt"
        createFile(contents: textFileContents, path: noMapTextFilePath)
        let noMapMDFilePath = noMapDir + "/test.md"
        createFile(contents: textFileContents, path: noMapMDFilePath)
        for suffix in ["gif", "png", "jpg", "jpeg", "binary"] {
            createBinaryFile(contents: imageData, path: noMapDir + "/test." + suffix)
        }
        
        let mapDir = testRootDir + "/with-gophermap"
        createDir(mapDir)
        
        let mapDirMapPath = mapDir + "/gophermap"
        createFile(contents: subdirGophermap, path: mapDirMapPath)
    }
    
    func removeTestGopherhole() {
        guard FileManager.default.fileExists(atPath: testRootDir) else { return }
        do {
            try FileManager.default.removeItem(atPath: testRootDir)
        } catch {
            XCTFail("Unexpected error while removing test gopherhole at \(testRootDir): \(error)")
        }
    }
    
    /// Convenience function for creating Handlers' dataHandler callback
    ///
    /// - Returns: tuple of (callback, expectation) which callback will satisfy on completion
    func buildDataHandlerAndExpectation() -> (HandlerDataHandler, XCTestExpectation) {
        let handlerWrittenExpectation = expectation(description: "handler write happened")
        let dataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
            handlerWrittenExpectation.fulfill()
            writeComplete(data.count)
        }
        return (dataHandler, handlerWrittenExpectation)
    }
    
    /// Convenience function for creating Handlers' handler-complete callback
    ///
    /// - Returns: tuple of (callback, expectation) which callback will satisfy on completion
    func buildCompletionAndExpectation() -> (HandlerCompletion, XCTestExpectation) {
        let handlerCompletionExpectation = expectation(description: "handler completion happened")
        let completion = {
            handlerCompletionExpectation.fulfill()
        }
        return (completion, handlerCompletionExpectation)
    }

    /// Does the error handler fire its callbacks as expected?
    func testErrorHandler() {
        let (dataHandler, handlerWrittenExpectation) = buildDataHandlerAndExpectation()
        let (completion, handlerCompletionExpectation) = buildCompletionAndExpectation()
        _ = ErrorHandler(request: "", error: HandlerTestsError.testError, dataHandler: dataHandler, handlerCompletion: completion)
        wait(for: [handlerWrittenExpectation, handlerCompletionExpectation], timeout: 1)
    }
    
    /// Does the file handler throw when it can't list a directory?
    func testFileHandlerThrowsCouldNotList() {
        let cfg = FileHandlerConfiguration(root: "this directory does not exist")

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
    
    /// Does the file handler throw when it can't find a file?
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
    
    /// Does the file handler send the root gophermap?
    func testFileHandlerSendsRootGophermap() {
        let cfg = FileHandlerConfiguration(root: testRootDir)
        let dataHandlerExpectation = expectation(description: "Root gophermap was written out")
        let dataHandler: HandlerDataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
            guard let s = String(bytes: data, encoding: .utf8) else { return XCTFail("Could not decode data in handler's data handler function") }
            XCTAssert(s == self.rootGophermap + handlerEndOfTransmissionString, "Unexpected root gophermap. Got '\(s)', expected '\(self.rootGophermap + handlerEndOfTransmissionString)'")
            dataHandlerExpectation.fulfill()
            writeComplete(data.count)
        }
        let (handlerCompletion, handlerCompletionExpectation) = buildCompletionAndExpectation()
        do {
            _ = try FileHandler(request: "", configuration: cfg, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
        } catch {
            XCTFail("Unexpected error in request for root gophermap: \(error)")
        }
        wait(for: [dataHandlerExpectation, handlerCompletionExpectation], timeout: 1)
    }
    
    /// Do we send an authored subdir gophermap?
    func testFileHandlerSendsAuthoredSubdirGophermap() {
        let cfg = FileHandlerConfiguration(root: testRootDir)
        let dataHandlerExpectation = expectation(description: "Subdir gophermap was written out")
        let dataHandler: HandlerDataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
            guard let s = String(bytes: data, encoding: .utf8) else { return XCTFail("Could not decode data in handler's data handler function") }
            XCTAssert(s == self.subdirGophermap + handlerEndOfTransmissionString, "Unexpected subdir gophermap. Got '\(s)', expected '\(self.subdirGophermap + handlerEndOfTransmissionString)'")
            dataHandlerExpectation.fulfill()
            writeComplete(data.count)
        }
        let (handlerCompletion, handlerCompletionExpectation) = buildCompletionAndExpectation()
        do {
            _ = try FileHandler(request: "with-gophermap/", configuration: cfg, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
        } catch {
            XCTFail("Unexpected error in request for subdir gophermap: \(error)")
        }
        wait(for: [dataHandlerExpectation, handlerCompletionExpectation], timeout: 1)
    }
    
    /// Do we send a generated subdir gophermap?
    func testFileHandlerSendsGeneratedSubdirGophermap() {
        let cfg = FileHandlerConfiguration(root: testRootDir)
        let dataHandlerExpectation = expectation(description: "Subdir gophermap was written out")
        let dataHandler: HandlerDataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
            guard let s = String(bytes: data, encoding: .utf8) else { return XCTFail("Could not decode data in handler's data handler function") }
            let expectedItemTypesAndFiles = [
                ("0", "test.txt"),
                ("0", "test.md"),
                ("g", "test.gif"),
                ("I", "test.png"),
                ("I", "test.jpg"),
                ("I", "test.jpeg"),
                ("9", "test.binary")
            ]
            let expectedGeneratedGophermap = expectedItemTypesAndFiles
                .sorted { (a, b) -> Bool in
                    return a.1 < b.1
                }
                .map { t -> String in
                    return "\(t.0)\(t.1)\tno-gophermap/\(t.1)"
                }
                .joined(separator: "\r\n")
            XCTAssert(s == expectedGeneratedGophermap + handlerEndOfTransmissionString, "Unexpected subdir gophermap. Got '\(s)', expected '\(expectedGeneratedGophermap + handlerEndOfTransmissionString)'")
            dataHandlerExpectation.fulfill()
            writeComplete(data.count)
        }
        let (handlerCompletion, handlerCompletionExpectation) = buildCompletionAndExpectation()
        do {
            _ = try FileHandler(request: "no-gophermap/", configuration: cfg, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
        } catch {
            XCTFail("Unexpected error in request for subdir gophermap: \(error)")
        }
        wait(for: [dataHandlerExpectation, handlerCompletionExpectation], timeout: 1)
    }
    
    func tryGettingTextFile(path: String) {
        let cfg = FileHandlerConfiguration(root: testRootDir)
        let dataHandlerExpectation = expectation(description: "Text file was written out")
        let dataHandler: HandlerDataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
            guard let s = String(bytes: data, encoding: .utf8) else { return XCTFail("Could not decode data in handler's data handler function") }
            XCTAssert(s == self.textFileContents + handlerEndOfTransmissionString, "Unexpected file contents. Got '\(s)', expected '\(self.subdirGophermap + handlerEndOfTransmissionString)'")
            dataHandlerExpectation.fulfill()
            writeComplete(data.count)
        }
        let (handlerCompletion, handlerCompletionExpectation) = buildCompletionAndExpectation()
        do {
            _ = try FileHandler(request: path, configuration: cfg, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
        } catch {
            XCTFail("Unexpected error in request for text file \(path): \(error)")
        }
        wait(for: [dataHandlerExpectation, handlerCompletionExpectation], timeout: 1)
    }
    
    /// Do text files get sent properly?
    func testFileHandlerSendsTextFilesProperly() {
        tryGettingTextFile(path: "no-gophermap/test.txt")
        tryGettingTextFile(path: "no-gophermap/test.md")
    }
    
    func tryGettingBinaryFile(path: String) {
        let cfg = FileHandlerConfiguration(root: testRootDir)
        let dataHandlerExpectation = expectation(description: "Data file was written out")
        let dataHandler: HandlerDataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
            XCTAssert(data == self.imageData, "Unexpected filecontents. Got \(data.count) bytes, expected \(self.imageData.count) bytes")
            dataHandlerExpectation.fulfill()
            writeComplete(data.count)
        }
        let (handlerCompletion, handlerCompletionExpectation) = buildCompletionAndExpectation()
        do {
            _ = try FileHandler(request: path, configuration: cfg, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
        } catch {
            XCTFail("Unexpected error in request for data file \(path): \(error)")
        }
        wait(for: [dataHandlerExpectation, handlerCompletionExpectation], timeout: 1)
    }
    
    func testFileHandlerSendsDataFilesProperly() {
        tryGettingBinaryFile(path: "no-gophermap/test.gif")
        tryGettingBinaryFile(path: "no-gophermap/test.png")
        tryGettingBinaryFile(path: "no-gophermap/test.jpg")
        tryGettingBinaryFile(path: "no-gophermap/test.jpeg")
        tryGettingBinaryFile(path: "no-gophermap/test.binary")
    }
    
    func testTraverseOutOfGopherholeAndReadDir() {
        let cfg = FileHandlerConfiguration(root: testRootDir)
        let dataHandler: HandlerDataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
        }
        do {
            _ = try FileHandler(request: "../", configuration: cfg, dataHandler: dataHandler, handlerCompletion: { })
            XCTFail("Expected error in request for enclosing directory")
        } catch {
            return
        }
    }
    
    func testTraverseOutOfHoleAndReadFile() {
        let illegalFilePath = "/tmp/illegal"
        createFile(contents: "🧙‍♂️ NONE SHALL PASS", path: illegalFilePath)
        let cfg = FileHandlerConfiguration(root: testRootDir)
        let dataHandler: HandlerDataHandler = { (data: Data, writeComplete: @escaping (Int) -> Void) in
        }
        do {
            _ = try FileHandler(request: "../illegal", configuration: cfg, dataHandler: dataHandler, handlerCompletion: { })
            XCTFail("Expected error in request for file in enclosing directory")
        } catch {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: illegalFilePath)
        } catch {
            XCTFail("Unexpected error while removing test gopherhole at \(illegalFilePath): \(error)")
        }
    }
}
