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
}

struct HelloFriendHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    
    func start() {
        let output = "Hello friend\r\n"
        var outputData = Data(output.utf8)
        while outputData.count > 0 {
            let len = self.delegate.handlerHasData(outputData)
            outputData.removeSubrange(0..<len)
        }
        self.delegate.complete()
    }
}

struct ErrorHandler: Handler {
    let request: String
    let delegate: HandlerDelegate
    let error: Error
    
    func start() {
        let output = "Error: \(error)"
        var outputData = Data(output.utf8)
        while outputData.count > 0 {
            let len = self.delegate.handlerHasData(outputData)
            outputData.removeSubrange(0..<len)
        }
        self.delegate.complete()
    }
}
