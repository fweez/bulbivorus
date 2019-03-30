//
//  RouterTests.swift
//  bulbivorusTests
//
//  Created by Ryan Forsythe on 3/29/19.
//

import XCTest
@testable import bulbivorusCore

class RouterTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testShortRequest() {
        let cfg = RouterConfiguration(maxRequestLength: 20, routes: [])
        var r = Router(configuration: cfg)
        let testRequest = "less than 20"
        do {
            try r.appendToRequest(testRequest)
            XCTAssert(r.request.count == testRequest.count)
        } catch {
            XCTFail("Threw while appending safe length: \(error)")
        }
    }
    
    func testMultipleAppends() {
        let cfg = RouterConfiguration(maxRequestLength: 20, routes: [])
        var r = Router(configuration: cfg)
        let testRequestPt1 = "less than 20"
        do {
            try r.appendToRequest(testRequestPt1)
            XCTAssert(r.request.count == testRequestPt1.count)
        } catch {
            XCTFail("Threw while appending safe length: \(error)")
        }
        let testRequestPt2 = ", still"
        do {
            try r.appendToRequest(testRequestPt2)
            XCTAssert(r.request.count == (testRequestPt1.count + testRequestPt2.count))
        } catch {
            XCTFail("Threw while appending safe length: \(error)")
        }
    }

    func testRequestTooLongSingleAppend() {
        let testRequest = "much, much too long"

        let cfg = RouterConfiguration(maxRequestLength: testRequest.count - 1, routes: [])
        var r = Router(configuration: cfg)
        do {
            try r.appendToRequest(testRequest)
            XCTFail("Should have thrown")
        } catch let error as Router.RequestError {
            XCTAssert(error == Router.RequestError.requestTooLong, "Should have thrown too long error, got: \(error)")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testRequestTooLongMultipleAppend() {
        let testRequest = "much, much too long"
        
        let cfg = RouterConfiguration(maxRequestLength: testRequest.count + 1, routes: [])
        var r = Router(configuration: cfg)
        do {
            try r.appendToRequest(testRequest)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
        
        do {
            try r.appendToRequest(testRequest)
            XCTFail("Should have thrown")
        } catch let error as Router.RequestError {
            XCTAssert(error == Router.RequestError.requestTooLong, "Should have thrown too long error, got: \(error)")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testFinished() {
        let testRequest = "hi there"
        let cfg = RouterConfiguration(maxRequestLength: nil, routes: [])
        var r = Router(configuration: cfg)
        do {
            try r.appendToRequest(testRequest)
            XCTAssertFalse(r.finished, "Should not be finished")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
        do {
            try r.appendToRequest("\r\n")
            XCTAssert(r.finished, "Should be finished now")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testHandlerGenerates() {
        let testRequest = "hi"
        let cfg = RouterConfiguration(maxRequestLength: nil, routes: [Route(kind: .helloFriend, requestMatch: testRequest, handlerConfiguration: nil)])
        var r = Router(configuration: cfg)
        r.dataHandler = { (_,_) in return }
        r.handlerCompletion = { }
        do {
            try r.appendToRequest(testRequest + "\r\n")
        } catch {
            XCTFail("Unexpected error from router: \(error)")
        }
        let h = r.buildHandler()
        
        XCTAssert(((h as? HelloFriendHandler) != nil), "Handler should have been a HelloFriendHandler")
    }
    
    func testRouteErrorHandler() {
        let testRequest = "hi"
        let cfg = RouterConfiguration(maxRequestLength: nil, routes: [Route(kind: .helloFriend, requestMatch: testRequest, handlerConfiguration: nil)])
        var r = Router(configuration: cfg)
        r.dataHandler = { (_,_) in return }
        r.handlerCompletion = { }
        do {
            try r.appendToRequest(testRequest + " here's an error!\r\n")
        } catch {
            XCTFail("Unexpected error from router: \(error)")
        }
        let h = r.buildHandler()
        guard let errorHandler = h as? ErrorHandler else {
            XCTFail("Handler should have been a ErrorHandler")
            return
        }
        guard let error = errorHandler.error as? Router.RequestError else {
            XCTFail("Error should have been a request error")
            return
        }
        XCTAssert(error == Router.RequestError.noRouteForRequest, "Error should have been a no-route error")
    }
    
    func testRegexRoutes() {
        let testRequest = "hi.*"
        
        let cfg = RouterConfiguration(maxRequestLength: nil, routes: [Route(kind: .helloFriend, requestMatch: testRequest, handlerConfiguration: nil)])
        var r = Router(configuration: cfg)
        r.dataHandler = { (_,_) in return }
        r.handlerCompletion = { }
        for matchingRequest in ["hi", "high", "hi.", "hi/", "hi🐶"] {
            r.request = ""
            do {
                try r.appendToRequest(matchingRequest + "\r\n")
            } catch {
                XCTFail("Unexpected error from router: \(error)")
            }
            let h = r.buildHandler()
            
            XCTAssert(((h as? HelloFriendHandler) != nil), "Handler for request '\(matchingRequest)' should have been a HelloFriendHandler, was a \(String(reflecting: h))")
        }
        
        for nonmatchingRequest in ["h", "hooli", "h.i", "/hi"] {
            r.request = ""
            do {
                try r.appendToRequest(nonmatchingRequest + "\r\n")
            } catch {
                XCTFail("Unexpected error from router: \(error)")
            }
            let h = r.buildHandler()
            
            guard let errorHandler = h as? ErrorHandler else {
                XCTFail("Handler should have been a ErrorHandler")
                return
            }
            guard let error = errorHandler.error as? Router.RequestError else {
                XCTFail("Error should have been a request error")
                return
            }
            XCTAssert(error == Router.RequestError.noRouteForRequest, "Error should have been a no-route error")
        }
    }
    
    func testSeveralRoutes() {
        let route1RequestMatch = "hi"
        let route1 = Route(kind: .helloFriend, requestMatch: route1RequestMatch, handlerConfiguration: nil)
        let route2RequestMatch = "file"
        let route2Cfg = FileHandlerConfiguration(root: ".")
        let route2 = Route(kind: .file, requestMatch: route2RequestMatch, handlerConfiguration: route2Cfg)
        let cfg = RouterConfiguration(maxRequestLength: nil, routes: [route1, route2])
        var r = Router(configuration: cfg)
        r.dataHandler = { (_,_) in return }
        r.handlerCompletion = { }
        
        let route1Request = "hi"
        do {
            try r.appendToRequest(route1Request + "\r\n")
        } catch {
            XCTFail("Unexpected error from router: \(error)")
        }
        let h1 = r.buildHandler()
        
        XCTAssert(((h1 as? HelloFriendHandler) != nil), "Handler for request '\(route1Request)' should have been a HelloFriendHandler, was a \(String(reflecting: h1))")
        
        let route2Request = "file"
        r.request = ""
        do {
            try r.appendToRequest(route2Request + "\r\n")
        } catch {
            XCTFail("Unexpected error from router: \(error)")
        }
        let h2 = r.buildHandler()
        
        guard let errorHandler = h2 as? ErrorHandler else {
            XCTFail("Handler should have been a ErrorHandler, was \(String(reflecting: h2))")
            return
        }
        guard let error = errorHandler.error as? FileHandler.FileError else {
            XCTFail("Error should have been a file handler file error, was \(String(reflecting: errorHandler.error))")
            return
        }
        XCTAssert(error == FileHandler.FileError.fileDoesNotExist, "Error should have been a file does not exist")
    }
}
