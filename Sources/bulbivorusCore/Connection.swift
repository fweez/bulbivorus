//
//  Connection.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/19/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation
import Socket

class Connection {
    static let connectionQueue = DispatchQueue.global(qos: .userInteractive)
    let connectionQueue: DispatchQueue
    var configuration: ConnectionConfiguration
    let completion: (_ finishedSocket: ReaderWriter) -> Void
    
    var socket: ReaderWriter
    var router: Router
    var handler: Handler?
    
    var stopped: Bool = false
    
    static var defaultReadChunkSize = 512
    static var defaultWriteChunkSize = 512
    
    init(_ clientSocket: ReaderWriter, configuration: ConnectionConfiguration, connectionCompletion: @escaping (ReaderWriter) -> Void) {
        socket = clientSocket
        self.configuration = configuration
        self.completion = connectionCompletion
        
        connectionQueue = DispatchQueue(label: "com.rmf.bulbivorus.connectionQueue.\(socket.socketfd)", target: Connection.connectionQueue)
        router = Router(configuration: configuration.routerConfiguration)
        router.dataHandler = writeDataToSocket
        router.handlerCompletion = handlerComplete
    }
    
    func writeDataToSocket(data: Data, writeCompletion: @escaping (Int) -> Void) -> Void {
        let chunkSize = self.configuration.writeChunkBytes ?? Connection.defaultWriteChunkSize
        self.connectionQueue.async { [unowned self] in
            var regionStart = 0
            while self.stopped == false {
                let writtenDataSize = min(data.underestimatedCount - regionStart, chunkSize - 1)
                guard writtenDataSize > 0 else { break }
                let thisChunk = data[regionStart..<(regionStart + writtenDataSize)]
                do {
                    let actualWriteSize = try self.socket.write(from: thisChunk)
                    regionStart = regionStart + actualWriteSize
                }
                catch {
                    writeCompletion(-1)
                }
                
            }
            writeCompletion(regionStart)
        }
    }
    
    func handlerComplete() -> Void {
        self.stopped = true
        self.handler = nil
        self.completion(self.socket)
    }
    
    func start() {
        connectionQueue.async { [unowned self] in
            let readCapacity = self.configuration.readChunkBytes ?? Connection.defaultReadChunkSize

            while self.handler == nil && self.stopped == false {
                var readBuffer = Data(capacity: readCapacity)
                do {
                    let len = try self.socket.read(into: &readBuffer)
                    guard len > 0 else { break }
                    guard let s = String(bytes: readBuffer, encoding: .utf8) else { throw Router.RequestError.requestCouldNotBeDecoded }
                    try self.router.appendToRequest(s)
                    if self.router.finished {
                        self.handler = self.router.buildHandler()
                    }
                }
                catch let error as Router.RequestError {
                    let dataHandler = self.router.dataHandler ?? { (_,_) in return }
                    let handlerCompletion = self.router.handlerCompletion ?? { }
                    self.handler = ErrorHandler(request: self.router.request, error: error, dataHandler: dataHandler, handlerCompletion: handlerCompletion)
                }
                catch { return assertionFailure("Unhandled error reading from client: \(error)") }
            }
        }
    }
    
    deinit {
        socket.close()
    }
}
