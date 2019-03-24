//
//  Handler.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/24/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

protocol HandlerDelegate {
    /// Takes data, tries to write it out, runs callback when complete
    func handlerHasData(_ data: Data, completion: @escaping (Int) -> Void)
    /// Signals the delegate that we're done here
    func complete()
}

protocol Handler {
    var request: String { get }
    var delegate: HandlerDelegate { get }
    
    func start() -> Void
    
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
        delegate.handlerHasData(d) { bytesWritten in
            guard bytesWritten > 0 else {
                return self.delegate.complete()
            }
            let nextData = d[bytesWritten...]
            guard nextData.count > 0 else {
                return self.delegate.complete()
            }
            self.sendData(nextData)
        }
    }
}

struct HelloFriendHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    
    func start() {
        self.sendString("Hello friend\r\n")
    }
}

struct ErrorHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    let error: Error
    
    func start() {
        self.sendString("Error: \(self.error)")
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
            if self.request.suffix(1) == "/" || self.request == "" {
                try self.sendList()
            } else {
                try self.send(documentLocation: self.request)
            }
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
