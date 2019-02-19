//
//  Connection.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/19/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

class Connection: NSObject, StreamDelegate {
    let readStream: InputStream!
    let writeStream: OutputStream!
    
    init(readStream: InputStream, writeStream: OutputStream) {
        self.readStream = readStream
        self.writeStream = writeStream
        
        super.init()
        
        self.readStream.delegate = self
        self.writeStream.delegate = self
    }
    
    func open() {
        self.readStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        self.writeStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        self.readStream.open()
        self.writeStream.open()
    }
    
    func close() {
        self.readStream.close()
        self.writeStream.close()
        self.readStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        self.writeStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
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
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Finished opening read stream")
        case Stream.Event.hasBytesAvailable:
            print("Read stream has bytes")
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
