//
//  Configuration.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/25/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

struct ServerConfiguration {
    let port = 70
    
    let connectionConfiguration = ConnectionConfiguration()
}

struct ConnectionConfiguration {
    let readChunkBytes = 256
    let writeChunkBytes = 256
    
    let routerConfiguration = RouterConfiguration()
}

struct RouterConfiguration {
    let maxRequestLength = 1024
}
