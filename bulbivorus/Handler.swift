//
//  Handler.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/24/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

protocol HandlerDelegate {
    /// Takes data, tries to write some of it out, returns the length written
    func handlerHasData(_ data: Data) -> Int
    /// Signals the delegate that we're done here
    func complete()
}

protocol Handler {
    var request: String { get }
    var delegate: HandlerDelegate { get }
    
    func start() -> Void
    
    func sendString(_ s: String) -> Void
}

extension Handler {
    func sendString(_ s: String) {
        var output = s + "\r\n\r\n.\r\n"
        var outputData = Data(output.utf8)
        while outputData.count > 0 {
            let len = self.delegate.handlerHasData(outputData)
            outputData.removeSubrange(0..<len)
        }
    }
}

struct HelloFriendHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    
    func start() {
        self.sendString("Hello friend\r\n")
        self.delegate.complete()
    }
}

struct ErrorHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    let error: Error
    
    func start() {
        self.sendString("Error: \(self.error)")
        self.delegate.complete()
    }
}

enum FileHandlerError: Error {
    case fileDoesNotExist
    case couldNotListDirectory
}

struct FileHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    let configuration: FileHandlerConfiguration
    
    func start() {
        do {
            if self.request.suffix(1) == "/" {
                try self.sendList()
            } else {
                try self.send(documentLocation: self.request)
            }
            self.delegate.complete()
        } catch {
            let h = ErrorHandler(request: self.request, delegate: self.delegate, error: error)
            h.start()
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
        let path = self.configuration.root + documentLocation
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw FileHandlerError.fileDoesNotExist
        }
        let s = try String(contentsOfFile: path)
        self.sendString(s)
    }
}
