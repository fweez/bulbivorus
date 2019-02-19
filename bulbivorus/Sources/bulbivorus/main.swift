//
//  main.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/18/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

let outputQueue = OperationQueue.init()
outputQueue.maxConcurrentOperationCount = 8

var connections: [Connection] = []

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
    
    let connection = Connection(readStream: readStream, writeStream: writeStream)
    connections.append(connection)
    connection.open()
}

let connectCallBack: CFSocketCallBack = { (s: CFSocket?, callbackType: CFSocketCallBackType, address: CFData?, rawData: UnsafeRawPointer?, info: UnsafeMutableRawPointer?) -> Void in
    guard let rawData = rawData else {
        print("Callback type \(callbackType.rawValue): Nil rawData")
        return
    }
    guard callbackType == CFSocketCallBackType.acceptCallBack else {
        print("Callback type \(callbackType.rawValue), not accept")
        return
    }
    let launderedData = Data(bytes: rawData, count: MemoryLayout.size(ofValue: rawData))
    let handle: CFSocketNativeHandle = launderedData.withUnsafeBytes { $0.pointee }
    acceptConnection(handle: handle)
    
}

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
