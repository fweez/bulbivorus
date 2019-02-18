// swift-tools-version:4.0
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
        /* Add your package dependencies in here
        .package(url: "https://github.com/AlwaysRightInstitute/cows.git",
                 from: "1.0.0"),
        */
    ],

    targets: [
        .target(name: "bulbivorus", 
                dependencies: [
                  /* Add your target dependencies in here, e.g.: */
                  // "cows",
                ])
    ]
)
