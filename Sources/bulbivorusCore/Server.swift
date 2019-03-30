//
//  Server.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/25/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation
import Socket

public class Server {
    static var defaultPort = 70
    
    let socketHandlerQueue = DispatchQueue.global(qos: .userInteractive)
    var listenerSocket: Socket? = nil
    var connections: [Int32: Connection] = [:]
    public var configuration: ServerConfiguration = try! ServerConfiguration()
    var stopped = false
    
    public init() {
        
    }
    
    deinit {
        shutdownConnections()
    }
    
    public func start() {
        do { try listenerSocket = Socket.create(family: .inet) }
        catch { assertionFailure("Could not start listener socket: \(error)") }
        
        guard let socket = listenerSocket else {
            assertionFailure("Socket unexpectedly nil!")
            return
        }
        
        do { try socket.listen(on: configuration.port ?? Server.defaultPort) }
        catch { assertionFailure("Socket failed while setting up listener: \(error)") }
        
        while self.stopped == false {
            do {
                let clientSocket = try socket.acceptClientConnection()
                let newConnection = Connection(clientSocket, configuration: self.configuration.connectionConfiguration, connectionCompletion: connectionFinished)
                socketHandlerQueue.sync { [unowned self, clientSocket] in
                    self.connections[clientSocket.socketfd] = newConnection
                }
                newConnection.start()
            } catch {
                assertionFailure("Failure while accepting client connection: \(error)")
            }
        }
    }
    
    func shutdownConnections() {
        socketHandlerQueue.sync {
            self.connections = [:]
        }
    }

    func connectionFinished(finishedSocket: ReaderWriter) {
        let fd = finishedSocket.socketfd
        socketHandlerQueue.sync { [unowned self, finishedSocket] in
            finishedSocket.close()
            self.connections[fd] = nil
            dump(self.connections)
        }
    }
}
