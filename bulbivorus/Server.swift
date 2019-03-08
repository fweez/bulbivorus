//
//  Server.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/25/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

class Server {
    static let shared = Server()
    
    let connectionsQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
    var connections: [Connection] = []
    var configuration: ServerConfiguration = try! ServerConfiguration()
    
    static var defaultPort = 70
    static func startListener() {
        let socketRef = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, CFStreamEventType.hasBytesAvailable.rawValue, Server.connectCallBack, nil)
        
        var sin = sockaddr_in()
        let addrSize = socklen_t(INET_ADDRSTRLEN)
        sin.sin_len = UInt8(addrSize)
        sin.sin_family = sa_family_t(AF_INET)
        sin.sin_port = UInt16(Server.shared.configuration.port ?? self.defaultPort).bigEndian
        sin.sin_addr.s_addr = INADDR_ANY
        
        let sinSize = MemoryLayout.size(ofValue: sin)
        let sinData = Data(bytes: &sin, count: sinSize)
        let ptrSinData = UnsafeMutablePointer<UInt8>.allocate(capacity: sinSize)
        sinData.copyBytes(to: ptrSinData, count: sinSize)
        let sinCFData = CFDataCreate(kCFAllocatorDefault, ptrSinData, MemoryLayout.size(ofValue: sin))
        
        let error = CFSocketSetAddress(socketRef, sinCFData)
        
        guard error == .success else {
            print("Failure opening socket: \(error.rawValue)")
            exit(1)
        }
        
        print("Opened socket successfully")
        let socketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socketRef, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), socketSource, CFRunLoopMode.defaultMode)
        CFRunLoopRun()
    }
    
    static func nativeHandleFrom(rawData: UnsafeRawPointer?, callbackType: CFSocketCallBackType) -> CFSocketNativeHandle? {
        guard let rawData = rawData else {
            print("Callback type \(callbackType.rawValue): Nil rawData")
            return nil
        }
        guard callbackType == CFSocketCallBackType.acceptCallBack else {
            print("Callback type \(callbackType.rawValue), not accept")
            return nil
        }
        let launderedData = Data(bytes: rawData, count: MemoryLayout.size(ofValue: rawData))
        return launderedData.withUnsafeBytes { $0.pointee }
    }
    
    static let connectCallBack: CFSocketCallBack = { (s: CFSocket?, callbackType: CFSocketCallBackType, address: CFData?, rawData: UnsafeRawPointer?, info: UnsafeMutableRawPointer?) -> Void in
        if let handle = Server.nativeHandleFrom(rawData: rawData, callbackType: callbackType) {
            Server.shared.acceptConnection(handle: handle)
        }
    }
    
    func acceptConnection(handle: CFSocketNativeHandle) {
        print("Accepted connection")
        var rs: Unmanaged<CFReadStream>?
        var ws: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, handle, &rs, &ws)
        guard let readStream = rs?.takeRetainedValue() as InputStream? else {
            print("Could not open read stream")
            return
        }
        guard let writeStream = ws?.takeRetainedValue() as OutputStream? else {
            print("Could not open write stream")
            return
        }
        
        CFReadStreamSetProperty(readStream, CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
        CFWriteStreamSetProperty(writeStream, CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
        
        let connection = Connection(readStream: readStream, writeStream: writeStream, onQueue: self.connectionsQueue, configuration: self.configuration.connectionConfiguration)
        print("Connections count before filter: \(connections.count)")
        connections = self.connections.filter( { $0.isOpen })
        print("Connections count after filter: \(connections.count)")
        self.connections.append(connection)
        connection.open()
    }
}
