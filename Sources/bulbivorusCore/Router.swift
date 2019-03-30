//
//  Router.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/24/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

struct Router {
    let configuration: RouterConfiguration
    var dataHandler: HandlerDataHandler? = nil
    var handlerCompletion: HandlerCompletion? = nil
    var request: String
    
    init(configuration: RouterConfiguration) {
        self.configuration = configuration
        self.request = ""
    }

    static var maxRequestLength = 1024
    
    enum RequestError: Error {
        case requestTooLong
        case requestCouldNotBeDecoded
        case requestNotFinished
        case noRouteForRequest
        case configurationError
    }
    
    mutating func appendToRequest(_ s: String) throws {
        let maxReqLen = configuration.maxRequestLength ?? Router.maxRequestLength
        guard request.count + s.count <= maxReqLen else  {
            throw Router.RequestError.requestTooLong
        }
        request.append(s)
    }
    
    var finished: Bool {
        let maxReqLen = configuration.maxRequestLength ?? Router.maxRequestLength
        guard request.count < maxReqLen else { return false }
        return request.hasSuffix("\r\n")
    }
    
    func buildHandler() -> Handler  {
        guard let dataHandler = dataHandler, let handlerCompletion = handlerCompletion else {
            assertionFailure("Tried to build handler before data handler and completion set")
            return ErrorHandler(request: request, error: Router.RequestError.requestNotFinished, dataHandler: { (_,_) in return }, handlerCompletion: { })
        }
        
        guard finished else {
            return ErrorHandler(request: request, error: Router.RequestError.requestNotFinished, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
        }
        
        let trimmedRequest = self.request.trimmingCharacters(in: .whitespacesAndNewlines)
        
        for route in configuration.routes {
            guard let range = trimmedRequest.range(of: route.requestMatch, options: .regularExpression), range.lowerBound == trimmedRequest.startIndex, range.upperBound == trimmedRequest.endIndex else { continue }
            
            switch route.kind {
            case .helloFriend: return HelloFriendHandler(request: trimmedRequest, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
            case .file:
                guard let cast = route.handlerConfiguration as? FileHandlerConfiguration?, let config = cast else {
                    return ErrorHandler(request: self.request, error: Router.RequestError.configurationError, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
                }
                do {
                    return try FileHandler(request: trimmedRequest, configuration: config, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
                } catch {
                    return ErrorHandler(request: self.request, error: error, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
                }
            }
        }
        
        return ErrorHandler(request: self.request, error: Router.RequestError.noRouteForRequest, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
    }
}
