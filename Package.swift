// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SWWebAppServer",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SWWebAppServer",
            targets: ["SWWebAppServer"]),
        .executable(name: "SWWebAppServerTest", targets: ["SWWebAppServerTest"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "SWWebAppServer"),
        .target(name: "SWWebAppServerTest", dependencies: ["SWWebAppServer"]),
        .testTarget(
            name: "SWWebAppServerTests",
            dependencies: ["SWWebAppServer"]
        ),
    ]
)
