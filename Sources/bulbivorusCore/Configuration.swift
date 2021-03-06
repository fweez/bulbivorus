//
//  Configuration.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/25/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

public struct ServerConfiguration {
    /// What port to run the server on. Gopher default is 70.
    let port: Int?
    
    let connectionConfiguration: ConnectionConfiguration
    
    init() throws {
        port = nil
        let fhCfg = FileHandlerConfiguration(root: "/var/gopherhole")
        let routes = [
            Route(kind: .file, requestMatch: "/.*", handlerConfiguration: fhCfg),
        ]
        let routerCfg = RouterConfiguration(maxRequestLength: nil, routes: routes)
        self.connectionConfiguration = ConnectionConfiguration(readChunkBytes: nil, writeChunkBytes: nil, routerConfiguration: routerCfg)
    }
}

extension ServerConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case port
        case connectionConfiguration = "connection"
        case readChunkBytes
        case writeChunkBytes
        case maxRequestLength
        case routes
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        port = try? values.decode(Int.self, forKey: .port)
        let readChunkBytes = try? values.decode(Int.self, forKey: .readChunkBytes)
        let writeChunkBytes = try? values.decode(Int.self, forKey: .writeChunkBytes)
        let maxRequestLength = try? values.decode(Int.self, forKey: .maxRequestLength)
        let routes = try values.decode(Array<Route>.self, forKey: .routes)
        
        let routerCfg = RouterConfiguration(maxRequestLength: maxRequestLength, routes: routes)
        connectionConfiguration = ConnectionConfiguration(readChunkBytes: readChunkBytes, writeChunkBytes: writeChunkBytes, routerConfiguration: routerCfg)
    }
}

public struct ConnectionConfiguration {
    /// Size of the read buffer, in bytes
    let readChunkBytes: Int?
    /// Size of the write buffer, in bytes
    let writeChunkBytes: Int?
    
    let routerConfiguration: RouterConfiguration
}

extension ConnectionConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case readChunkBytes
        case writeChunkBytes
        case routerConfiguration = "router"
    }
}

public struct RouterConfiguration: Codable {
    /// Maximum length of requests, in characters
    let maxRequestLength: Int?
    
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

enum HandlerKind: String, Codable {
    case helloFriend
    case file
}

public struct Route {
    /// The handler to use for this route
    let kind: HandlerKind
    /// A regex to use to match request paths
    let requestMatch: String
    /// Handler configurations for this route
    let handlerConfiguration: Codable?
}

extension Route: Decodable {
    enum CodingKeys: String, CodingKey {
        case kind, requestMatch, handlerConfiguration
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        kind = try values.decode(HandlerKind.self, forKey: .kind)
        requestMatch = try values.decode(String.self, forKey: .requestMatch)
        switch kind {
        case .helloFriend: handlerConfiguration = nil // no valid configuration
        case .file: handlerConfiguration = try values.decode(FileHandlerConfiguration.self, forKey: .handlerConfiguration)
        }
    }
}

extension Route: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Route.CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(requestMatch, forKey: .requestMatch)
        guard let cfg = handlerConfiguration else { return }
        switch kind {
        case .helloFriend: break // no valid configuration
        case .file:
            guard let fhcfg = cfg as? FileHandlerConfiguration else { return }
            try container.encode(fhcfg, forKey: .handlerConfiguration)
        }
    }
}

public struct FileHandlerConfiguration: Codable {
    /// Root of a directory to serve with a FileHandler
    let root: String
}

