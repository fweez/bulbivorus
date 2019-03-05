//
//  Handler.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/24/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation

protocol HandlerDelegate {
    /// Takes data, tries to write some of it out, returns the length written
    func handlerHasData(_ data: Data) -> Int
    /// Signals the delegate that we're done here
    func complete()
}

protocol Handler {
    var request: String { get }
    var delegate: HandlerDelegate { get }
    
    func start() -> Void
    
    func sendString(_ s: String) -> Void
}

extension Handler {
    func sendString(_ s: String) {
        var outputData = Data(s.utf8)
        while outputData.count > 0 {
            let len = self.delegate.handlerHasData(outputData)
            outputData.removeSubrange(0..<len)
        }
    }
}

struct HelloFriendHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    
    func start() {
        self.sendString("Hello friend\r\n")
        self.delegate.complete()
    }
}

struct ErrorHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    let error: Error
    
    func start() {
        self.sendString("Error: \(self.error)")
        self.delegate.complete()
    }
}

struct FileHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    let configuration: FileHandlerConfiguration
    
    func start() {
        defer { self.delegate.complete() }
        
        do {
            let s = try String(contentsOfFile: self.configuration.root + self.request)
            self.sendString(s)
        }
        catch {
            self.sendString("Error: \(error)")
        }
        
    }
}
