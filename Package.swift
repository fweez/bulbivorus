// swift-tools-version:5.0
//
//  Package.swift
//  bulbivorus
//
//  Created by Ryan Forsythe on 2/18/19.
//  Copyright © 2019 rmf. All rights reserved.
//
import PackageDescription

let package = Package(
    name: "bulbivorus",

    dependencies: [
        .package(url: "https://github.com/IBM-Swift/BlueSocket.git", from:"1.0.8"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from:"1.0.17"),
    ],

    targets: [
        .target(
            name: "bulbivorus",
            dependencies: ["bulbivorusCore", "Signals"]),
        .target(
            name: "bulbivorusCore",
            dependencies:["Socket"]),
        .testTarget(
            name: "bulbivorusTests",
            dependencies: ["bulbivorusCore"])
    ]
)
