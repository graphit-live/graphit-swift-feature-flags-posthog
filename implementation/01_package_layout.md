# Package layout

## Manifest target

```swift
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
        .package(path: "../graphit-swift-feature-flags")
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
```

The final dependency declaration may use the repository's normal local or remote package policy. The public product remains one library: `GraphitFeatureFlagsPostHog`.

No public testing product in v1.

## Source tree

Start small and concrete. Split only around cohesive boundaries.

```text
Sources/GraphitFeatureFlagsPostHog/
  PostHogFeatureFlagClient.swift
  PostHogFeatureFlagConfiguration.swift
  PostHogFeatureFlagContext.swift
  PostHogFeatureFlagEvaluation.swift
  PostHogFeatureFlagError.swift
  PostHogHost.swift
  PostHogEvaluationRuntime.swift
  PostHogTextValues.swift
  Internal/
    PostHogValidation.swift
    PostHogFlagsRequest.swift
    PostHogFlagsResponse.swift
    PostHogFlagsMapper.swift
    PostHogHTTPTransport.swift

Tests/GraphitFeatureFlagsPostHogTests/
  ConfigurationValidationTests.swift
  ContextValidationTests.swift
  RequestConstructionTests.swift
  ResponseMappingTests.swift
  ClientEvaluationTests.swift
  ErrorMappingTests.swift
  CancellationTests.swift
  READMEExamplesTests.swift
  Support/
    FakePostHogHTTPTransport.swift
```

The tree is a guide, not a mandate. Fewer files are acceptable when fewer files are clearer.

## Import rules

- Core target may import `Foundation` for `URL`, `URLRequest`, `URLSession`, `Data`, and JSON encoding/decoding.
- Core target imports `GraphitFeatureFlags` for mapping into `FeatureFlagSnapshot` and `FeatureFlags`.
- No SwiftUI, UIKit, AppKit, Combine, Observation, OSLog, GraphitCache, PostHog vendor SDK, or third-party imports in v1.
- Tests may import `Foundation`, `GraphitFeatureFlags`, `GraphitFeatureFlagsPostHog`, and `Testing`.

## Access rules

- `public` only for the exact v1 API contract.
- Every public type and public member needs a documentation comment.
- Implementation details stay `internal` or `private`.
- Internal request, response, mapper, validation, and transport types are not public API.
- `package` should not be needed in v1; use it only if a future multi-target package creates a real cross-target collaboration need.
- Test doubles stay under `Tests`; no public test-support product.

## No generated code or resources

No code generation, macros, generated schemas, bundled PostHog clients, or package resources in v1.

## Dependency direction

```text
GraphitFeatureFlags                 // pure core values and evaluator
GraphitFeatureFlagsPostHog          // depends on GraphitFeatureFlags and maps PostHog responses
App                                 // owns state, refresh cadence, caching, UI, and analytics
```

The PostHog package must not change the core package's API or pull app lifecycle concerns into core.
