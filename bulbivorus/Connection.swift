//
//  Connection.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/19/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

class Connection: NSObject {
    let connectionQueue: DispatchQueue
    let readStream: InputStream
    let writeStream: OutputStream
    var configuration: ConnectionConfiguration
    
    var router: Router
    var handler: Handler?
    
    var isOpen: Bool = false
    
    init(readStream: InputStream, writeStream: OutputStream, onQueue target: DispatchQueue, configuration: ConnectionConfiguration) {
        self.connectionQueue = DispatchQueue(label: "com.rmf.bulbivorus.connectionQueue", target: target)
        self.readStream = readStream
        self.writeStream = writeStream
        self.configuration = configuration
        self.router = Router(configuration: configuration.routerConfiguration)
        super.init()
        
        self.readStream.delegate = self
        self.writeStream.delegate = self
    }
    
    func open() {
        self.connectionQueue.async {
            print("Opened connection")
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
                let chunksize = self.configuration.readChunkBytes
                let data = UnsafeMutablePointer<UInt8>.allocate(capacity: chunksize)
                stream.read(data, maxLength: chunksize)
                router.request.append(String(cString: data))
                guard router.finished == false else {
                    break
                }
            }
            
            self.handler = self.router.buildHandler(delegate: self)
            self.handler?.start()
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

extension Connection: HandlerDelegate {
    func handlerHasData(_ data: Data) -> Int {
        let chunkSize = self.configuration.writeChunkBytes
        let buff = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: chunkSize)
        let (_, endIndex) = buff.initialize(from: data)
        guard let p = buff.baseAddress else { return 0 }
        self.writeStream.write(p, maxLength: endIndex)
        return endIndex
    }
    
    func complete() {
        self.close()
    }
}
