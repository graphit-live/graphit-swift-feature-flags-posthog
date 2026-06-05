// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "GraphitFeatureFlagsPostHog",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "GraphitFeatureFlagsPostHog",
            targets: ["GraphitFeatureFlagsPostHog"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/graphit-live/graphit-swift-feature-flags",
            exact: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "GraphitFeatureFlagsPostHog",
            dependencies: [
                .product(name: "GraphitFeatureFlags", package: "graphit-swift-feature-flags")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GraphitFeatureFlagsPostHogTests",
            dependencies: ["GraphitFeatureFlagsPostHog"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
