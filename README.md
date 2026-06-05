# GraphitFeatureFlagsPostHog

GraphitFeatureFlagsPostHog is a small Swift SDK that evaluates PostHog feature flags through PostHog's public `/flags?v=2` endpoint and maps the result into immutable `GraphitFeatureFlags` values.

V1 is intentionally explicit: it does not own app state, caching, refresh loops, analytics, exposure tracking, or UI integration. Network work happens only when `evaluateFeatureFlags(for:)` is called. Creating a `PostHogFeatureFlagClient` validates configuration and performs no network or filesystem I/O.

## Platform and toolchain

- Swift 6.3.x
- Swift language mode 6
- iOS 18+ primary support
- macOS 15+ package support for SwiftPM builds/tests and Mac app use
- No Linux support claim in v1
- No third-party Swift dependencies
- Depends on `GraphitFeatureFlags`
- No GraphitCache dependency in v1

## Installation

Add this package with Swift Package Manager and depend on the `GraphitFeatureFlagsPostHog` library product.

```swift
dependencies: [
    .package(url: "https://github.com/graphit-live/graphit-swift-feature-flags-posthog.git", from: "0.1.0")
]
```

```swift
.product(name: "GraphitFeatureFlagsPostHog", package: "graphit-swift-feature-flags-posthog")
```

This package also depends on `GraphitFeatureFlags`, which supplies `FeatureFlags`, `FeatureFlagSnapshot`, `FeatureFlagKey`, and related provider-neutral values.

## Quick start

Call PostHog explicitly, then read flags from the returned immutable `FeatureFlags` evaluator.

```swift
import GraphitFeatureFlags
import GraphitFeatureFlagsPostHog

enum AppFlags {
    static let newHome = FeatureFlagKey("new-home")
}

let client = try PostHogFeatureFlagClient(configuration: .init(
    projectToken: PostHogProjectToken("ph_project_token"),
    host: .usCloud
))

let context = PostHogFeatureFlagContext(
    distinctID: PostHogDistinctID("user-123")
)

let evaluation = try await client.evaluateFeatureFlags(for: context)
let flags = evaluation.featureFlags

if flags.isEnabled(AppFlags.newHome) {
    // Show the new home experience.
}
```

`PostHogFeatureFlagClient.init(configuration:)` does not contact PostHog. The only v1 operation that performs network work is `evaluateFeatureFlags(for:)`, and each call performs one `/flags?v=2` request for the supplied context.

## Updating app state

`FeatureFlags` is immutable. To update feature flag state, evaluate again and replace an app-owned value.

```swift
var currentFlags = try FeatureFlags([])

let refreshed = try await client.evaluateFeatureFlags(for: context)
currentFlags = refreshed.featureFlags
```

This package does not provide a mutable store, observation stream, callback registry, background refresh loop, SwiftUI model, or process-wide singleton.

## Evaluation context

A request uses one PostHog distinct ID and can optionally include groups and evaluation context tags.

```swift
let context = PostHogFeatureFlagContext(
    distinctID: PostHogDistinctID("user-123"),
    groups: [
        PostHogGroup(type: "company", id: "graphit")
    ],
    evaluationContexts: [
        PostHogEvaluationContextTag("ios"),
        PostHogEvaluationContextTag("production")
    ]
)
```

Groups are encoded only when present. Evaluation context tags are encoded only when present. The SDK sorts validated groups and tags during request construction so requests are deterministic.

## Runtime filtering and User-Agent

PostHog filters flags by runtime using request headers and User-Agent detection. The default `.client` runtime sends a package-owned User-Agent that starts with:

```text
posthog-ios/1.0.0
```

For the first release the full default is:

```text
posthog-ios/1.0.0 graphit-sdk/0.1.0
```

This intentionally asks PostHog for client-runtime and all-runtime flags. `customUserAgent(_:)` is available only as an advanced escape hatch when an integration intentionally needs a different PostHog runtime signal. Custom User-Agent text is validated at client construction and redacted from descriptions and public errors.

## Request timeout

Configure the timeout applied to one evaluation request with `requestTimeout`.

```swift
let client = try PostHogFeatureFlagClient(configuration: .init(
    projectToken: PostHogProjectToken("ph_project_token"),
    requestTimeout: .seconds(5)
))
```

The timeout must be greater than zero. V1 has no retry policy; callers retry by explicitly calling `evaluateFeatureFlags(for:)` again when app policy allows it.

## Partial and quota-limited results

PostHog can return successful HTTP responses that are incomplete or quota-limited. These are metadata, not thrown errors.

```swift
let evaluation = try await client.evaluateFeatureFlags(for: context)

if evaluation.isPartial {
    // PostHog reported that some flags could not be computed.
    // Decide whether to use, cache, merge, or discard this result.
}

if evaluation.quotaLimits.contains(.featureFlags) {
    // Feature flag evaluation is quota-limited for this project.
}

let requestID = evaluation.requestID
```

`evaluation.featureFlags` contains the flags PostHog returned.

## App-owned caching

GraphitFeatureFlagsPostHog does not cache, persist, choose TTLs, merge stale results, or depend on GraphitCache in v1. Apps that need caching can cache the provider-neutral `FeatureFlagSnapshot` explicitly.

```swift
import Foundation
import GraphitFeatureFlags

let data = try JSONEncoder().encode(evaluation.featureFlags.snapshot)
let cachedSnapshot = try JSONDecoder().decode(FeatureFlagSnapshot.self, from: data)
let cachedFlags = try FeatureFlags(snapshot: cachedSnapshot)
```

A correct app-owned cache key should account for inputs that can affect PostHog results, such as host, project token identity, distinct ID, groups, evaluation contexts, and runtime policy. The SDK does not define this key because it may contain private identifiers and app-specific privacy decisions.

## Errors and cancellation

`evaluateFeatureFlags(for:)` is `async throws` and preserves cancellation. Cancellation is not wrapped in `PostHogFeatureFlagError`.

Package-owned failures use `PostHogFeatureFlagError` categories:

- `invalidConfiguration` for invalid client configuration
- `invalidInput` for malformed evaluation context values
- `unexpectedStatusCode` for non-2xx PostHog responses
- `transportFailure` for sanitized network failures after preserving cancellation
- `invalidResponse` for malformed `/flags` response data
- `invalidFeatureFlagSnapshot` when mapped PostHog data is rejected by `GraphitFeatureFlags` validation

Public error descriptions are sanitized and must not include raw project tokens, distinct IDs, group IDs, custom User-Agent text, request bodies, or raw response bodies.

## Privacy and redaction

Treat project tokens, distinct IDs, group IDs, and custom User-Agent text as sensitive. The SDK redacts descriptions for `PostHogProjectToken`, `PostHogDistinctID`, `PostHogGroup`, and custom runtime descriptions. It does not log by default.

Evaluation context tags and feature flag keys/variants may be visible to application code through their raw values. Do not put secrets or private data in those values if your app logs or displays them.

## No analytics or exposure tracking

This package does not send `$feature_flag_called` events, attach `$feature/<flag-key>` event properties, capture analytics, deduplicate exposure, batch events, or import the PostHog vendor SDK. Reads from `FeatureFlags` are side-effect-free. Apps own analytics and exposure policy separately.

## Non-goals in v1

GraphitFeatureFlagsPostHog v1 does not include:

- PostHog admin APIs or feature-flag CRUD
- local evaluation
- generated clients or PostHog vendor SDK imports
- provider protocols or registries
- retry/backoff policy
- caching, persistence, TTLs, stale fallback, or GraphitCache integration
- mutable stores, observation streams, callbacks, Combine, SwiftUI, UIKit, AppKit, or Observation adapters
- automatic analytics or exposure tracking
- person property overrides, group property overrides, GeoIP override headers, or arbitrary JSON public values
- process-wide singletons, service locators, property wrappers, macros, dynamic member lookup, or task-local dependency lookup
- refresh loops, timers, app lifecycle hooks, or background tasks

## Maintainer release check

The first release default User-Agent is locked as:

```text
posthog-ios/1.0.0 graphit-sdk/0.1.0
```

Before future release tags, update/check only `graphit-sdk/<version>` so it matches the tag without the leading `v`. Keep the `posthog-ios/1.0.0` token first so PostHog detects the client runtime marker.
