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
    
    func buildHandler(delegate: HandlerDelegate) throws -> Handler  {
        guard self.finished else {
            throw Router.RequestError.requestNotFinished
        }
        
        return HelloFriendHandler(request: self.request, delegate: delegate)
    }
}
