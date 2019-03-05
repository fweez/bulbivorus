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
    var request: String = ""

    init(configuration: RouterConfiguration) {
        self.configuration = configuration
    }
    
    enum RequestError: Error {
        case requestTooLong
        case requestNotFinished
        case noRouteForRequest
    }
    
    mutating func appendToRequest(_ s: String) throws {
        guard self.request.count + s.count <= self.configuration.maxRequestLength else  {
            throw Router.RequestError.requestTooLong
        }
        self.request.append(s)
    }
    
    var finished: Bool {
        guard self.request.count < self.configuration.maxRequestLength else { return false }
        return self.request.hasSuffix("\r\n")
    }
    
    func buildHandler(delegate: HandlerDelegate) -> Handler  {
        guard self.finished else {
            return ErrorHandler(request: self.request, delegate: delegate, error: Router.RequestError.requestNotFinished)
        }
        
        let trimmedRequest = self.request.trimmingCharacters(in: .whitespacesAndNewlines)
        
        for route in configuration.routes {
            guard let range = trimmedRequest.range(of: route.requestMatch, options: .regularExpression), range.lowerBound == trimmedRequest.startIndex, range.upperBound == trimmedRequest.endIndex else { continue }
            
            switch route.kind {
            case .helloFriend: return HelloFriendHandler(request: trimmedRequest, delegate: delegate)
            case .file: return FileHandler(request: trimmedRequest, delegate: delegate, configuration: route.handlerConfiguration[.file] as! FileHandlerConfiguration)
            }
        }
        
        return ErrorHandler(request: self.request, delegate: delegate, error: Router.RequestError.noRouteForRequest)
    }
}
