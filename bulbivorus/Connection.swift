//
//  Connection.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/19/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

class Connection: NSObject {
    static let connectionQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    static var connections: [Connection] = []
    
    static func startListener() {
        let socketRef = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, CFStreamEventType.hasBytesAvailable.rawValue, connectCallBack, nil)
        
        var sin = sockaddr_in()
        let addrSize = socklen_t(INET_ADDRSTRLEN)
        sin.sin_len = UInt8(addrSize)
        sin.sin_family = sa_family_t(AF_INET)
        sin.sin_port = UInt16(70).bigEndian
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
    
    static func acceptConnection(handle: CFSocketNativeHandle) {
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
        
        let connection = Connection(readStream: readStream, writeStream: writeStream)
        print("Connections count before filter: \(connections.count)")
        connections = Connection.connections.filter( { $0.isOpen == false })
        print("Connections count after filter: \(connections.count)")
        self.connections.append(connection)
        connection.open()
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
        if let handle = Connection.nativeHandleFrom(rawData: rawData, callbackType: callbackType) {
            Connection.acceptConnection(handle: handle)
        }
    }
    
    let readStream: InputStream
    let writeStream: OutputStream
    var isOpen: Bool = false
    var router = Router()
    
    init(readStream: InputStream, writeStream: OutputStream) {
        self.readStream = readStream
        self.writeStream = writeStream
        
        super.init()
        
        self.readStream.delegate = self
        self.writeStream.delegate = self
    }
    
    func open() {
        Connection.connectionQueue.async {
            self.isOpen = true
            self.readStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            self.writeStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            self.readStream.open()
            self.writeStream.open()
            RunLoop.current.run()
        }
    }
    
    func close() {
        print("Closing streams & removing from runloop")
        self.isOpen = false
        self.readStream.close()
        self.writeStream.close()
        self.readStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        self.writeStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
}

extension Connection: StreamDelegate {
    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        if stream == self.readStream {
            self.handleReadStream(stream, handle: eventCode)
        } else if stream == self.writeStream {
            self.handleWriteStream(stream, handle: eventCode)
        } else {
            print("Unknown stream!")
        }
    }
    
    func handleReadStream(_ stream: Stream, handle eventCode: Stream.Event) {
        guard let stream = stream as? InputStream else {
            print("Couldn't coerce stream into input stream")
            return
        }
        
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Finished opening read stream")
        case Stream.Event.hasBytesAvailable:
            print("Read stream has bytes")
            while stream.hasBytesAvailable {
                let chunksize = 256
                let data = UnsafeMutablePointer<UInt8>.allocate(capacity: chunksize)
                stream.read(data, maxLength: chunksize)
                router.request.append(String(cString: data))
                guard router.finished == false else {
                    self.close()
                    return
                }
            }
            
        case Stream.Event.hasSpaceAvailable:
            print("Read stream has space ?!?!?")
        case Stream.Event.errorOccurred:
            print("Read stream error occurred")
        case Stream.Event.endEncountered:
            print("Read stream end encountered")
        default:
            print("Read stream unknown event code: \(eventCode)")
        }
    }
    
    func handleWriteStream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Finished opening write stream")
        case Stream.Event.hasBytesAvailable:
            print("Write stream has bytes available ?!?!")
        case Stream.Event.hasSpaceAvailable:
            print("Write stream has space")
        case Stream.Event.errorOccurred:
            print("Write stream error occurred")
        case Stream.Event.endEncountered:
            print("Write stream end encountered")
        default:
            print("Write stream unknown event code: \(eventCode)")
        }
    }
}
