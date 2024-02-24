// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JVSecurity",
	defaultLocalization: "en",
	platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "JVSecurity",
            targets: ["JVSecurity"]),
    ],
	// Dependencies declare other packages that this package depends on.
	dependencies: [
		.package(url: "https://github.com/TheMisfit68/JVUI.git", branch: "main"),
		.package(url: "https://github.com/TheMisfit68/JVSwiftCore.git", branch: "main"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "JVSecurity",
			dependencies: [
				"JVUI",
				"JVSwiftCore"
			]
		),
        .testTarget(
            name: "JVSecurityTests",
            dependencies: ["JVSecurity"]),
    ]
)
