//
//  Handler.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/24/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

typealias HandlerDataHandler = (_ writeData: Data, _ writeComplete: @escaping (Int) -> Void) -> Void
typealias HandlerCompletion = () -> Void

let handlerEndOfTransmissionString = "\r\n\r\n.\r\n"

protocol Handler {
    var request: String { get }
    var dataHandler: HandlerDataHandler { get }
    var handlerCompletion: HandlerCompletion { get }
    
    func sendString(_ s: String) -> Void
    func sendData(_ d: Data) -> Void
}

extension Handler {
    func sendString(_ s: String) {
        let output = s + handlerEndOfTransmissionString
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

struct FileHandler: Handler {
    let request: String
    var dataHandler: HandlerDataHandler
    var handlerCompletion: HandlerCompletion
    let configuration: FileHandlerConfiguration
    
    enum FileError: Error {
        case fileDoesNotExist
        case couldNotListDirectory
    }
    
    enum FileType {
        case map
        case text
        case gif
        case image
        case binary
        
        init(path: String) {
            if path.suffix("gophermap".count) == "gophermap" {
                self = .map
                return
            }
            if path.suffix(4) == ".gif" {
                self = .gif
                return
            }
            
            let imageFileSuffixes = [".png", ".jpg", ".jpeg"]
            for suffix in imageFileSuffixes {
                if path.suffix(suffix.count) == suffix {
                    self = .image
                    return
                }
            }
            
            let textFileSuffixes = [".txt", ".md"]
            for suffix in textFileSuffixes {
                if path.suffix(suffix.count) == suffix {
                    self = .text
                    return
                }
            }
            
            // Fall back on binary
            self = .binary
        }
        
        var itemType: String {
            switch self {
            case .map: return "1"
            case .text: return "0"
            case .gif: return "g"
            case .image: return "I"
            case .binary: return "9"
            }
        }
    }
    
    init(request: String, configuration: FileHandlerConfiguration, dataHandler: @escaping HandlerDataHandler, handlerCompletion: @escaping HandlerCompletion) throws {
        self.request = request
        self.configuration = configuration
        self.dataHandler = dataHandler
        self.handlerCompletion = handlerCompletion
        
        if request.suffix(1) == "/" || request == "" {
            try sendList()
        } else {
            try send(documentLocation: self.request)
        }
    }
    
    func sendList() throws {
        let mapLocation: String
        if request.suffix(1) == "/" {
            mapLocation = request + "gophermap"
        } else {
            mapLocation = request + "/gophermap"
        }
        if FileManager.default.isReadableFile(atPath: configuration.root + "/" + mapLocation) {
            try send(documentLocation: mapLocation)
        } else {
            let dirPath = configuration.root + "/" + request
            guard FileManager.default.isReadableFile(atPath: dirPath) else {
                throw FileHandler.FileError.couldNotListDirectory
            }
            
            /// FIXME: Cache file attributes?
            let generatedMap = try FileManager.default.contentsOfDirectory(atPath: dirPath)
                .sorted()
                .map { fileName -> String in
                    let type = FileType(path: fileName)
                    return "\(type.itemType)\(fileName)\t\(request + fileName)"
                }
                .joined(separator: "\r\n")
            sendString(generatedMap)
        }
    }
    
    func send(documentLocation: String) throws {
        var root = self.configuration.root
        if root.suffix(1) != "/" && documentLocation.prefix(1) != "/" {
            root.append("/")
        }
        let path = root + documentLocation
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw FileHandler.FileError.fileDoesNotExist
        }
        switch FileType(path: documentLocation) {
        case .text, .map:
            self.sendString(try String(contentsOfFile: path))
        case .image, .gif, .binary:
            let pathURL = URL(fileURLWithPath: path)
            self.sendData(try Data(contentsOf: pathURL))
        }
    }
}
