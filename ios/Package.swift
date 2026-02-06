// swift-tools-version:5.9
// Package.swift for Supabase SDK dependency reference
// Note: This is used for package reference. The actual Xcode project
// should add Supabase via File > Add Package Dependencies.

import PackageDescription

let package = Package(
    name: "NeverGoneDemo",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "NeverGoneDemo",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "NeverGoneDemo"
        ),
        .testTarget(
            name: "NeverGoneDemoTests",
            dependencies: ["NeverGoneDemo"],
            path: "NeverGoneDemoTests"
        )
    ]
)
