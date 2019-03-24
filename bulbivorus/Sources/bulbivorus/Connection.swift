//
//  Connection.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/19/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation
import Socket

protocol ConnectionDelegate {
    func finished(sender: Connection) -> Void
}

class Connection {
    static let connectionQueue = DispatchQueue.global(qos: .userInteractive)
    let connectionQueue: DispatchQueue
    var configuration: ConnectionConfiguration
    
    var delegate: ConnectionDelegate?
    var socket: Socket
    var router: Router
    var handler: Handler?
    
    var stopped: Bool = false
    
    static var defaultReadChunkSize = 512
    static var defaultWriteChunkSize = 512
    
    init(_ clientSocket: Socket, configuration: ConnectionConfiguration, delegate: ConnectionDelegate) {
        socket = clientSocket
        self.configuration = configuration
        self.delegate = delegate
        connectionQueue = DispatchQueue(label: "com.rmf.bulbivorus.connectionQueue.\(socket.socketfd)", target: Connection.connectionQueue)
        router = Router(configuration: configuration.routerConfiguration)
    }
    
    func start() {
        connectionQueue.async { [unowned self] in
            let readCapacity = self.configuration.readChunkBytes ?? Connection.defaultReadChunkSize

            while self.handler == nil && self.stopped == false {
                var readBuffer = Data(capacity: readCapacity)
                do {
                    guard try self.socket.read(into: &readBuffer) > 0 else { break }
                    guard let s = String(bytes: readBuffer, encoding: .utf8) else { return }
                    try self.router.appendToRequest(s)
                    print("Read value '\(s)' Request is now '\(self.router.request)' Router is finished: \(self.router.finished)")
                    if self.router.finished {
                        self.handler = self.router.buildHandler(delegate: self)
                        self.handler?.start()
                    }
                }
                catch let error as Router.RequestError {
                    self.handler = ErrorHandler(request: self.router.request, delegate: self, error: error)
                    self.handler?.start()
                }
                catch { return assertionFailure("Unhandled error reading from client: \(error)") }
            }
        }
    }
    
    deinit {
        print("Deinit connection with handle \(socket.socketfd)")
        socket.close()
    }
}

extension Connection: HandlerDelegate {
    func handlerHasData(_ data: Data, completion: @escaping (Int) -> Void) {
        print("handlerHasData called with '\(String(bytes: data, encoding: .utf8) ?? "<arg not encodable to string>")'")
        let chunkSize = self.configuration.writeChunkBytes ?? Connection.defaultWriteChunkSize
        connectionQueue.async { [unowned self] in
            var regionStart = 0
            while self.stopped == false {
                let writtenDataSize = min(data.underestimatedCount - regionStart, chunkSize - 1)
                guard writtenDataSize > 0 else { break }
                let thisChunk = data[regionStart..<(regionStart + writtenDataSize)]
                do { try self.socket.write(from: thisChunk) }
                catch {
                    print("Error writing '\(String(bytes: thisChunk, encoding: .utf8) ?? "<chunk not encodable to string>")' to socket: \(error)")
                    completion(-1)
                }
                regionStart = regionStart + writtenDataSize
            }
            print("Completed writing out handler data")
            completion(regionStart)
        }
    }
    
    func complete() {
        print("Handler for connection with handle \(socket.socketfd) is complete")
        stopped = true
        handler = nil
        delegate?.finished(sender: self)
    }
}
