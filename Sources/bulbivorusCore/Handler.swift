//
//  Handler.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/24/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

typealias HandlerDataHandler = (Data, @escaping (Int) -> Void) -> Void
typealias HandlerCompletion = () -> Void

protocol Handler {
    var request: String { get }
    var dataHandler: HandlerDataHandler { get }
    var handlerCompletion: HandlerCompletion { get }
    
    func sendString(_ s: String) -> Void
    func sendData(_ d: Data) -> Void
}

extension Handler {
    func sendString(_ s: String) {
        let output = s + "\r\n\r\n.\r\n"
        let outputData = Data(output.utf8)
        sendData(outputData)
    }
    
    func sendData(_ d: Data) {
        dataHandler(d) { bytesWritten in
            guard bytesWritten > 0 else {
                return self.handlerCompletion()
            }
            let nextData = d[bytesWritten...]
            guard nextData.count > 0 else {
                return self.handlerCompletion()
            }
            self.sendData(nextData)
        }
    }
}

struct HelloFriendHandler: Handler {
    let request: String
    let dataHandler: HandlerDataHandler
    let handlerCompletion: HandlerCompletion

    init(request: String, dataHandler: @escaping HandlerDataHandler, handlerCompletion: @escaping HandlerCompletion) {
        self.request = request
        self.dataHandler = dataHandler
        self.handlerCompletion = handlerCompletion
        self.sendString("Hello friend\r\n")
    }
}

struct ErrorHandler: Handler {
    let request: String
    var dataHandler: HandlerDataHandler
    var handlerCompletion: HandlerCompletion
    let error: Error
    
    init(request: String, error: Error, dataHandler: @escaping HandlerDataHandler, handlerCompletion: @escaping HandlerCompletion) {
        self.request = request
        self.dataHandler = dataHandler
        self.handlerCompletion = handlerCompletion
        self.error = error
        self.sendString("Error: \(self.error)")
    }
}

enum FileHandlerError: Error {
    case fileDoesNotExist
    case couldNotListDirectory
}

struct FileHandler: Handler {
    let request: String
    var dataHandler: HandlerDataHandler
    var handlerCompletion: HandlerCompletion
    let configuration: FileHandlerConfiguration
    
    init(request: String, configuration: FileHandlerConfiguration, dataHandler: @escaping HandlerDataHandler, handlerCompletion: @escaping HandlerCompletion) {
        self.request = request
        self.configuration = configuration
        self.dataHandler = dataHandler
        self.handlerCompletion = handlerCompletion
        
        do {
            if request.suffix(1) == "/" || request == "" {
                try sendList()
            } else {
                try send(documentLocation: self.request)
            }
        } catch {
            let _ = ErrorHandler(request: self.request, error: error, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
        }
    }
    
    func sendList() throws {
        let mapLocation = self.request + "gophermap"
        do {
            try self.send(documentLocation: mapLocation)
        } catch FileHandlerError.fileDoesNotExist {
            self.sendString("TODO: directory listings")
            throw FileHandlerError.couldNotListDirectory
        }
    }
    
    func send(documentLocation: String) throws {
        var root = self.configuration.root
        if root.suffix(1) != "/" {
            root.append("/")
        }
        let path = root + documentLocation
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw FileHandlerError.fileDoesNotExist
        }
        let s = try String(contentsOfFile: path)
        self.sendString(s)
    }
}
