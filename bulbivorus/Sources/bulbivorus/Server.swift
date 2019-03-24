//
//  Server.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/25/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation
import Socket

class Server {
    static var defaultPort = 70
    
    let socketHandlerQueue = DispatchQueue.global(qos: .userInteractive)
    var listenerSocket: Socket? = nil
    var connections: [Int32: Connection] = [:]
    var configuration: ServerConfiguration = try! ServerConfiguration()
    var stopped = false
    
    deinit {
        shutdownConnections()
    }
    
    func start() {
        do {
            try listenerSocket = Socket.create(family: .inet)
        } catch {
            assertionFailure("Could not start listener socket: \(error)")
            return
        }
        
        guard let socket = listenerSocket else {
            assertionFailure("Socket unexpectedly nil!")
            return
        }
        
        do {
            try socket.listen(on: configuration.port ?? Server.defaultPort)
        } catch {
            assertionFailure("Socket failed while setting up listener: \(error)")
        }
        
        while self.stopped == false {
            do {
                let clientSocket = try socket.acceptClientConnection()
                let newConnection = Connection(clientSocket, configuration: self.configuration.connectionConfiguration, delegate: self)
                socketHandlerQueue.sync { [unowned self, clientSocket] in
                    self.connections[clientSocket.socketfd] = newConnection
                }
                newConnection.start()
                print("Added connection with handle \(clientSocket.socketfd)")
            } catch {
                assertionFailure("Failure while accepting client connection: \(error)")
                return
            }
        }
    }
    
    func shutdownConnections() {
        socketHandlerQueue.sync {
            self.connections = [:]
        }
    }
}

extension Server: ConnectionDelegate {
    func finished(sender: Connection) {
        print("Connection with handle \(sender.socket.socketfd) is finished")
        let fd = sender.socket.socketfd
        socketHandlerQueue.sync { [unowned self, sender] in
            print("Destroying connection with handle \(fd)")
            sender.socket.close()
            self.connections[fd] = nil
            dump(self.connections)
        }
        dump(self.connections)
    }
}
