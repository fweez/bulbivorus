//
//  Socket+ReaderWriter.swift
//  bulbivorusCore
//
//  Created by Ryan Forsythe on 3/28/19.
//

import Foundation
import Socket

/// Testability -- wraps the elements of Socket that we actually use here
 protocol ReaderWriter {
    func write(from: Data) throws -> Int
    func read(into: inout Data) throws -> Int
    func close()
    var socketfd: Int32 { get }
}

extension Socket: ReaderWriter { }
