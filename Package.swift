// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Diesis",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "Diesis", targets: ["Diesis"]),
    ],
    dependencies: [
        .package(url: "https://github.com/web3swift-team/web3swift.git", "3.3.2"..<"4.0.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", "5.4.0"..<"6.0.0"),
    ],
    targets: [
        .target(
            name: "Diesis",
            dependencies: [
                .product(name: "web3swift", package: "web3swift"),
                .product(name: "BigInt", package: "BigInt"),
            ]
        ),
        .testTarget(
            name: "DiesisTests",
            dependencies: ["Diesis"]
        ),
    ]
)
