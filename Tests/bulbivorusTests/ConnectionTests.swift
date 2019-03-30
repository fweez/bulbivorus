//
//  ConnectionTests.swift
//  bulbivorusTests
//
//  Created by Ryan Forsythe on 3/28/19.
//

import XCTest
@testable import bulbivorusCore

class TestSocket: bulbivorusCore.ReaderWriter {
    var testCase: XCTestCase
    var writeCount = 0
    var writeDelay: UInt32 = 0
    
    init(testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    func write(from: Data) throws -> Int {
        sleep(writeDelay)
        writeCount += 1
        return from.count
    }
    
    var readData: Data?
    var readExpectation: XCTestExpectation?
    func read(into: inout Data) throws -> Int {
        guard let input = readData, input.count > 0 else { return 0 }
        
        let testData = input.prefix(ConnectionTests.readChunkBytes)
        if input.count > testData.count {
            readData = input.suffix(from: testData.count)
        } else {
            readData = nil
        }
        
        into.append(testData)
        if readData == nil, let e = readExpectation {
            e.fulfill()
        }
        return testData.count
    }
    
    var closed = false
    func close() {
        closed = true
    }
    
    var socketfd: Int32 = 0
}

class ConnectionTests: XCTestCase {
    var connection: bulbivorusCore.Connection!
    var testSocket: TestSocket!
    
    static var writeChunkBytes = 64
    static var readChunkBytes = 64
    override func setUp() {
        testSocket = TestSocket(testCase: self)
        let routerConfig = RouterConfiguration(maxRequestLength: nil, routes: [])
        let config = ConnectionConfiguration(readChunkBytes: ConnectionTests.readChunkBytes, writeChunkBytes: ConnectionTests.writeChunkBytes, routerConfiguration: routerConfig)
        connection = bulbivorusCore.Connection(testSocket, configuration: config, connectionCompletion: { (testSocket) in
            testSocket.close()
        })
    }

    override func tearDown() { }

    func testSimpleWrite() {
        let testOutput = "Hello world"
        let testData = Data(testOutput.utf8)
        let written = expectation(description: "Data was written")
        connection.writeDataToSocket(data: testData) { (count) in
            written.fulfill()
            XCTAssert(count == testData.count, "Written length should be the same as data length")
        }
        wait(for: [written], timeout: 5)
        XCTAssert(testSocket.writeCount == 1, "Should have been completed in one write")
        
    }

    func testVeryLongWrite() {
        let testData = Data(Array<uint8>(repeating: 7, count: ConnectionTests.writeChunkBytes + 1))
        let written = expectation(description: "Data was written")
        connection.writeDataToSocket(data: testData) { (count) in
            written.fulfill()
            XCTAssert(count == testData.count, "Written length should be the same as data length")
        }
        wait(for: [written], timeout: 5)
        XCTAssert(testSocket.writeCount == 2, "Should have been completed in two writes")
        
    }
    
    func testStopped() {
        testSocket.writeDelay = 2
        let testData = Data(Array<uint8>(repeating: 7, count: ConnectionTests.writeChunkBytes + 1))
        let written = expectation(description: "Data was written")
        connection.writeDataToSocket(data: testData) { (count) in
            written.fulfill()
            XCTAssert(count < testData.count, "Written length should not be the same as data length")
        }
        sleep(1)
        connection.stopped = true
        wait(for: [written], timeout: 5)
        XCTAssert(testSocket.writeCount == 1, "Should have only completed one write")
    }
    
    func testStartWithSmallRequest() {
        testSocket.readData = "hi".data(using: .utf8)!
        let readExpectation = expectation(description: "Read was called")
        testSocket.readExpectation = readExpectation
        connection.start()
        wait(for: [readExpectation], timeout: 5)
    }
    
    func testStartWithLargeRequest() {
        let readData = String(Array<Character>(repeating: "x", count: ConnectionTests.readChunkBytes * 2)).data(using: .utf8)!
        testSocket.readData = readData
        let readExpectation = expectation(description: "Read was called")
        testSocket.readExpectation = readExpectation
        connection.start()
        wait(for: [readExpectation], timeout: 5)
        XCTAssert(connection.router.request.count == readData.count, "Router should have entire request")
    }
    
    func testHandlerComplete() {
        connection.handlerComplete()
        XCTAssert(testSocket.closed == true)
    }
}
