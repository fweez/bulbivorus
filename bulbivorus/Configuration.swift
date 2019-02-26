//
//  Configuration.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/25/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

struct ServerConfiguration {
    /// What port to run the server on. Gopher default is 70.
    let port = 70
    
    let connectionConfiguration: ConnectionConfiguration
    
    init() throws {
        let routes = [Route(kind: .helloFriend, requestMatch: "/.*")]
        let routerCfg = RouterConfiguration(routes: routes)
        self.connectionConfiguration = ConnectionConfiguration(routerConfiguration: routerCfg)
    }
}

struct ConnectionConfiguration {
    /// Size of the read buffer, in bytes
    let readChunkBytes = 256
    /// Size of the write buffer, in bytes
    let writeChunkBytes = 256
    
    let routerConfiguration: RouterConfiguration
}

struct RouterConfiguration {
    /// Maximum length of requests, in characters
    let maxRequestLength = 1024
    
    let routes: [Route]
}

enum HandlerKind {
    case helloFriend
}

struct Route {
    /// The handler to use for this route
    let kind: HandlerKind
    /// A regex to use to match request paths
    let requestMatch: String
}

