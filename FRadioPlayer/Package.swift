// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FRadioPlayer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FRadioPlayer",
            targets: ["FRadioPlayer"]
        ),
    ],
    targets: [
        .target(
            name: "FRadioPlayer",
            path: "Sources"
        ),
    ]
)
