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
        let fhCfg = FileHandlerConfiguration(root: "/Users/ryan/gopherhole")
        let routes = [
            Route(kind: .helloFriend, requestMatch: "/hello", handlerConfiguration: [:]),
            Route(kind: .file, requestMatch: "/.*", handlerConfiguration: [.file: fhCfg]),
        ]
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
    
    /**
     List of routes to service.
     
     Overlapping routes are legal, but earlier matches will supercede later matches.
     Thus, a list of matches like this:
        ["/hi.*", "/hilarious", "/.*"]
     Will fire the first route on "/hilarious", and the last route on "/funny", and
     never fire the second route.
     
     A list of matches like:
        ["/hilarious", "/hi.*", "/.*"]
     Would fire the first route on "/hilarious", the second on "/hilarity", and the
     last on "/funny"
     */
    let routes: [Route]
}

enum HandlerKind {
    case helloFriend
    case file
}

struct Route {
    /// The handler to use for this route
    let kind: HandlerKind
    /// A regex to use to match request paths
    let requestMatch: String
    /// Handler configuration for this route
    let handlerConfiguration: [HandlerKind: Any]
}

struct FileHandlerConfiguration {
    /// Root of a directory to serve with a FileHandler
    let root: String
}

