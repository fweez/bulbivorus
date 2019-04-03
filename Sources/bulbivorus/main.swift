//
//  main.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/18/19.
//  Copyright © 2019 rmf. All rights reserved.
//

import Foundation
import Signals
import bulbivorusCore

func loadConfig() -> bulbivorusCore.ServerConfiguration? {
    let configDirs: [URL?] = [
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first,
        FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.localDomainMask).first,
        ]
    for configDir in configDirs {
        guard let configURL = configDir?.appendingPathComponent("bulbivorus-config.json") else { continue }
        print("Looking in \(configURL.absoluteString) for configuration")
        guard let configData = try? Data(contentsOf: configURL) else {
            print("Couldn't read contents of file.")
            continue
        }
        do {
            let config = try JSONDecoder().decode(ServerConfiguration.self, from: configData)
            print("Loaded config from \(configURL.absoluteString)")
            return config
        } catch {
            print("Error loading config: \(error)")
        }
    }
    return nil
}

let server = Server()

Signals.trap(signal: .hup) { _ in
    if let config = loadConfig() {
        server.configuration = config
    }
}

Signals.trap(signal: .term) { _ in
    server.shutdownConnections()
    exit(0)
}

if let config = loadConfig() {
    server.configuration = config
}
server.start()


