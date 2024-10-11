// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FileLock",
    platforms: [
      .macOS(.v10_15),
      .iOS(.v15),
      .macCatalyst(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FileLock",
            targets: ["FileLock"]),
        .library(
          name: "FileLockTesting",
          targets: ["FileLockTesting"]),
    ],
    dependencies: [
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FileLock",
            dependencies: [
            ]
        ),
        .target(
            name: "FileLockTesting",
            dependencies: [
              .byName(name: "FileLock"),
            ]
        ),
        .testTarget(
            name: "FileLockTests",
            dependencies: [
                "FileLock",
                "FileLockTesting"
            ]),
    ]
)
