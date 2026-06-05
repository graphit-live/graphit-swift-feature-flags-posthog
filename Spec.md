# GraphitFeatureFlagsPostHog Swift SDK — Minimal V1 Product and Engineering Specification

**Version:** Draft 4 minimal PostHog provider v1  
**Date:** 2026-06-05  
**Primary goal:** a small, explicit PostHog feature-flag evaluation adapter for `GraphitFeatureFlags`.  
**Core rule:** GraphitFeatureFlagsPostHog performs explicit PostHog feature-flag evaluation requests and maps the result into `GraphitFeatureFlags` values. It does not own app state, hidden refresh loops, caching, event capture, exposure tracking, or UI integration.

---

## 1. Product summary

GraphitFeatureFlagsPostHog v1 is a **PostHog-backed feature flag evaluation adapter** for the provider-agnostic `GraphitFeatureFlags` package.

It supports only:

- explicit calls to PostHog's `/flags?v=2` endpoint;
- PostHog project-token authentication through the request body;
- US Cloud, EU Cloud, and custom PostHog ingestion hosts;
- one distinct ID per evaluation request;
- optional PostHog groups;
- optional PostHog evaluation context tags;
- semantic PostHog runtime configuration, defaulting to client-runtime evaluation;
- configurable positive request timeout;
- mapping PostHog boolean and multivariate flag results into `FeatureFlags`;
- returning request metadata needed for callers to reason about partial results and quota limits.

It intentionally does **not** include PostHog admin APIs, feature-flag CRUD, personal API keys, local evaluation, PostHog `config=true` responses, event capture, automatic `$feature_flag_called` events, exposure tracking, caching, persistence, background refresh, observation streams, SwiftUI adapters, provider protocols, service locators, process-wide singletons, or GraphitCache integration in v1.

The intended app-facing flow is explicit:

```swift
let client = try PostHogFeatureFlagClient(configuration: .init(
    projectToken: PostHogProjectToken("ph_project_token"),
    host: .usCloud
))

let evaluation = try await client.evaluateFeatureFlags(
    for: .init(distinctID: PostHogDistinctID("user-123"))
)

let flags = evaluation.featureFlags

if flags.isEnabled(FeatureFlagKey("new-home")) {
    showNewHome()
}
```

Updating feature flag state means evaluating again and replacing the app-owned `FeatureFlags` value:

```swift
let refreshed = try await client.evaluateFeatureFlags(for: context)
currentFlags = refreshed.featureFlags
```

Network work happens only when an evaluation method is called. Initializers validate configuration only and must not contact PostHog.

The dependency direction is one-way:

```text
GraphitFeatureFlags                 // pure core values and evaluator
GraphitFeatureFlagsPostHog          // depends on GraphitFeatureFlags and maps PostHog responses
App                                 // owns state, refresh cadence, caching, UI, and analytics
```

---

## 2. Platform and toolchain

- Swift 6.3.x.
- Swift language mode 6.
- SwiftPM source package.
- Official v1 product focus: iOS 18+.
- Package also supports macOS 15+ for SwiftPM builds/tests and Mac app use.
- No Linux support claim in v1 unless the repository later adds Linux CI.
- No third-party Swift dependencies.
- Depends on `GraphitFeatureFlags`.
- Does not depend on GraphitCache in v1.
- Core target may import Foundation for `URL`, `URLRequest`, `URLSession`, `Data`, and JSON encoding/decoding.
- No SwiftUI, UIKit, AppKit, Combine, Observation, OSLog, or vendor SDK imports in v1.

Suggested manifest shape:

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

The final package dependency declaration may use the repository's normal local or remote package policy. The public product remains one library: `GraphitFeatureFlagsPostHog`.

---

## 3. Locked v1 decisions

### 3.1 Explicit network only

`PostHogFeatureFlagClient.init` validates configuration and creates a reusable resource-owning client. It must not perform I/O.

`evaluateFeatureFlags(for:)` is the only v1 public operation that contacts PostHog.

No feature flag read calls PostHog. Reads happen through the returned immutable `FeatureFlags` evaluator.

### 3.2 One PostHog request evaluates matching flags for one context

One call to `evaluateFeatureFlags(for:)` sends one HTTP POST to `/flags?v=2` for the supplied distinct ID, groups, and evaluation context tags. It asks PostHog to evaluate all flags matching that request context.

The SDK must not perform one HTTP request per feature flag.

PostHog billing and quota rules are provider-owned and can change outside this package. The SDK therefore avoids hidden calls and surfaces PostHog's `quotaLimited` response metadata so callers can decide how to handle limits.

### 3.3 Semantic runtime policy

PostHog filters returned flags based on runtime detection from request headers and User-Agent. The public API models this as a semantic `PostHogEvaluationRuntime`, not as a raw header field on the main configuration surface.

By default, the client uses `.client`, which sends a package-owned User-Agent containing a PostHog-recognizable client runtime marker such as `posthog-ios/`. This makes the runtime request intentional: client-runtime and all-runtime flags should be eligible, while server-only flags should not be accidentally requested by a generic `URLSession` User-Agent.

V1 includes `customUserAgent(_:)` only as an advanced escape hatch for integrations that intentionally need a different PostHog runtime signal. First-class server-side Swift runtime support is deferred until it can be designed explicitly as a semantic runtime mode, rather than relying on accidental headers.

### 3.4 Immutable state update

`GraphitFeatureFlags` remains immutable and provider-agnostic. This package must not add a mutable flag store.

Apps update state by replacing their app-owned `FeatureFlags` value with the result of a new explicit PostHog evaluation.

No actor-backed store, observation stream, callback registry, Combine publisher, SwiftUI model, or background refresh loop exists in v1.

### 3.5 Cache-friendly, not cached

Caching can reduce latency, offline failures, and PostHog usage. It is still not built into the base v1 provider.

The base provider intentionally stops at evaluation, extraction, validation, and mapping into package-owned values. It does not create cache keys, choose TTLs, keep stale snapshots, merge partial results, or decide when app state should update.

Cache policy depends on distinct ID, groups, evaluation contexts, host, project, runtime policy, TTL, privacy, stale-on-failure behavior, and app lifecycle. The base provider therefore returns `FeatureFlags`; apps that cache explicitly can use `evaluation.featureFlags.snapshot`.

A future separate caching adapter may depend on GraphitCache, but this package's v1 product does not.

### 3.6 No automatic analytics or exposure tracking

PostHog documents optional `$feature_flag_called` events and event properties such as `$feature/<flag-key>`. This package does not send those events or attach those properties in v1.

Reads from `FeatureFlags` remain side-effect-free. Apps that capture PostHog analytics events own event capture, exposure policy, batching, retry, privacy, and failure handling.

### 3.7 Public API stays package-owned

Do not expose `URLSession`, raw `URLResponse`, raw PostHog transport payloads, generated clients, or vendor SDK types in the main public API.

PostHog JSON request and response shapes are internal implementation details mapped into package-owned public values and `GraphitFeatureFlags` values.

### 3.8 No provider protocol in v1

Do not add `FeatureFlagProvider`, `PostHogProvider`, `FeatureFlagSource`, or similar public protocols. A protocol can be introduced later only after multiple concrete providers prove the shared shape.

### 3.9 No hidden global state

No `.shared`, service locator, process-wide mutable configuration, task-local dependency lookup, property wrapper, macro, dynamic member lookup, or implicit environment lookup exists in v1.

---

## 4. Concept model

### 4.1 Client

`PostHogFeatureFlagClient` is the public facade and resource owner. It is a `final class` because it owns immutable configuration and a package-owned reusable internal transport.

It is not `@MainActor`. It is safe to call from concurrent tasks. It does not retain app state or schedule background work.

The normal v1 implementation should not use `URLSession.shared`. It should create and reuse an internal session or transport owned by the client, preferably with an ephemeral `URLSessionConfiguration` so feature-flag evaluation does not persist cookies or URL-cache data by default. This transport remains an implementation detail and is not exposed as public API.

### 4.2 Configuration

`PostHogFeatureFlagConfiguration` contains the PostHog project token, host, semantic runtime policy, and request timeout required for evaluation requests.

Configuration is explicit. Invalid configuration is rejected when constructing the client.

### 4.3 Host

`PostHogHost` identifies the PostHog ingestion base URL.

Built-in hosts:

- `.usCloud` → `https://us.i.posthog.com`
- `.euCloud` → `https://eu.i.posthog.com`

Custom hosts support self-hosted PostHog deployments. Custom host validation should reject missing schemes, unsupported schemes, query strings, fragments, and non-root paths in v1.

### 4.4 Evaluation context

`PostHogFeatureFlagContext` identifies one PostHog evaluation request:

- one distinct ID;
- optional groups for group-based feature flags;
- optional evaluation context tags for PostHog evaluation-context filtering.

Evaluation context tags are set-like filters. Order is not meaningful, and duplicate tags do not express different behavior. Groups remain an array so duplicate group types can be represented and rejected instead of silently collapsed. Validated groups are sorted by `type` during request construction so tests and optional caller cache-key construction can be deterministic.

V1 does not include person property overrides, group property overrides, or GeoIP override headers. These are useful when PostHog's stored person, group, or GeoIP-derived properties are stale or missing, but they require a package-owned JSON value model, cache-key policy, error redaction policy, and privacy review before becoming public API.

### 4.5 Evaluation result

`PostHogFeatureFlagEvaluation` is the SDK-produced result of one PostHog evaluation call.

It contains:

- a validated immutable `FeatureFlags` evaluator ready for local reads;
- PostHog request ID when present;
- whether PostHog reported that some flags could not be computed;
- quota-limit categories reported by PostHog.

`errorsWhileComputingFlags == true` is not automatically thrown. PostHog can return a successful HTTP response with a partially computed flag set. When `isPartial == true`, `featureFlags` contains the values PostHog did return, but the evaluation may be incomplete; callers decide whether to use, cache, merge, or discard the result.

`quotaLimited` is not automatically thrown. If PostHog returns an empty flag set with `quotaLimited: ["feature_flags"]`, the SDK returns an empty `FeatureFlags` evaluator and exposes the quota metadata.

### 4.6 Mapping boundary

The provider maps external PostHog data into the core package's resolved values:

```text
PostHog /flags response
  -> internal response values
  -> FeatureFlagSnapshot
  -> FeatureFlags
```

The mapping boundary is where vendor quirks are normalized. Public callers should not need to inspect PostHog JSON.

---

## 5. Public API surface

All public declarations require documentation comments. Do not add public symbols outside this contract without explicit alignment.

### 5.1 `PostHogProjectToken`

```swift
public struct PostHogProjectToken: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Represents the PostHog project token used with the public `/flags` endpoint.
- Construction is nonvalidating.
- Client construction validates that the token is non-empty, contains no Unicode control scalars, and is no longer than 512 characters.
- `description` must be redacted and must not include the raw token.
- Do not log raw project tokens.

### 5.2 `PostHogDistinctID`

```swift
public struct PostHogDistinctID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Represents the PostHog `distinct_id` for one evaluation request.
- Construction is nonvalidating.
- Evaluation validates that the ID is non-empty, contains no Unicode control scalars, and is no longer than 1,024 characters.
- `description` must be redacted because distinct IDs may contain private user identifiers.
- Do not log raw distinct IDs by default.

### 5.3 `PostHogHost`

```swift
public struct PostHogHost: Hashable, Sendable {
    public static let usCloud: PostHogHost
    public static let euCloud: PostHogHost

    public let url: URL

    public init(_ url: URL)
}
```

Rules:

- Represents a PostHog ingestion base URL.
- `.usCloud` uses `https://us.i.posthog.com`.
- `.euCloud` uses `https://eu.i.posthog.com`.
- Construction is nonvalidating.
- Client construction validates URL shape.
- V1 builds the flags endpoint by appending `/flags` and query `v=2`.

### 5.4 `PostHogEvaluationRuntime`

```swift
public struct PostHogEvaluationRuntime: Hashable, Sendable, CustomStringConvertible {
    public static let client: PostHogEvaluationRuntime

    public static func customUserAgent(_ userAgent: String) -> PostHogEvaluationRuntime

    public var description: String { get }
}
```

Rules:

- Represents the PostHog runtime signal used for `/flags` runtime filtering.
- `.client` uses a package-owned User-Agent containing a PostHog-recognizable client runtime marker such as `posthog-ios/`.
- `customUserAgent(_:)` is an advanced escape hatch for integrations that intentionally need a different PostHog runtime signal.
- Construction is nonvalidating.
- Client construction validates custom User-Agent text when custom runtime is supplied.
- `description` must not expose custom User-Agent text; use a stable redacted description.
- Do not add `.server` in v1. Add first-class server-side Swift runtime support later as an explicit semantic mode.

### 5.5 `PostHogGroup`

```swift
public struct PostHogGroup: Hashable, Sendable, CustomStringConvertible {
    public let type: String
    public let id: String

    public init(type: String, id: String)

    public var description: String { get }
}
```

Rules:

- Represents one PostHog group used for group-based feature flags.
- Construction is nonvalidating.
- Evaluation validates non-empty `type` and `id`, no control scalars, type length no longer than 256 characters, ID length no longer than 1,024 characters, and no duplicate group types in a single context.
- `description` must be redacted because group IDs may contain private account, organization, or tenant identifiers.
- Group values are encoded into the request body as PostHog's `groups` object.
- Validated groups are sorted by `type` before request body construction for deterministic behavior; JSON object order is not a PostHog semantic.

### 5.6 `PostHogEvaluationContextTag`

```swift
public struct PostHogEvaluationContextTag: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Represents one PostHog evaluation context tag.
- Construction is nonvalidating.
- Evaluation validates non-empty text, no control scalars, and length no longer than 256 characters.
- Values are encoded into the request body as `evaluation_contexts`.

### 5.7 `PostHogFeatureFlagContext`

```swift
public struct PostHogFeatureFlagContext: Hashable, Sendable {
    public var distinctID: PostHogDistinctID
    public var groups: [PostHogGroup]
    public var evaluationContexts: Set<PostHogEvaluationContextTag>

    public init(
        distinctID: PostHogDistinctID,
        groups: [PostHogGroup] = [],
        evaluationContexts: Set<PostHogEvaluationContextTag> = []
    )
}
```

Rules:

- Represents all caller-provided inputs for one `/flags?v=2` evaluation request.
- Initializer is nonthrowing and does not perform I/O.
- Evaluation validates the context before building the request.
- `groups` are optional and needed only for group-based PostHog flags. Duplicate group types are rejected during evaluation validation. The request builder sorts validated groups by `type` before encoding.
- `evaluationContexts` are optional set-like filters for which tagged PostHog flags are evaluated. Order is not meaningful; request encoding sorts tags by raw value for deterministic tests and cache-key construction by callers.

### 5.8 `PostHogFeatureFlagConfiguration`

```swift
public struct PostHogFeatureFlagConfiguration: Sendable {
    public var projectToken: PostHogProjectToken
    public var host: PostHogHost
    public var runtime: PostHogEvaluationRuntime
    public var requestTimeout: Duration

    public init(
        projectToken: PostHogProjectToken,
        host: PostHogHost = .usCloud,
        runtime: PostHogEvaluationRuntime = .client,
        requestTimeout: Duration = .seconds(10)
    )
}
```

Rules:

- Represents immutable client configuration.
- Initializer is nonthrowing and does not perform I/O.
- Client construction validates the token, host, runtime, and request timeout.
- `runtime == .client` uses the package-owned default client runtime User-Agent.
- A custom runtime User-Agent is an escape hatch for advanced integrations. It must be non-empty, contain no control scalars, and be no longer than 512 characters when supplied.
- `requestTimeout` must be greater than zero. It controls the timeout applied to one PostHog evaluation request.
- Do not add retry, cache, analytics, or refresh policy to this v1 configuration.

### 5.9 `PostHogQuotaLimit`

```swift
public struct PostHogQuotaLimit: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public static let featureFlags: PostHogQuotaLimit

    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Represents one value from PostHog's `quotaLimited` response field.
- `.featureFlags` has raw value `"feature_flags"`.
- Unknown quota-limit categories are preserved as raw values.
- Not `Codable` in v1. Apps should cache `FeatureFlagSnapshot` when they need persistence, not PostHog response metadata.

### 5.10 `PostHogFeatureFlagEvaluation`

```swift
public struct PostHogFeatureFlagEvaluation: Sendable {
    public let featureFlags: FeatureFlags
    public let requestID: String?
    public let isPartial: Bool
    public let quotaLimits: Set<PostHogQuotaLimit>
}
```

Rules:

- SDK-produced result for one successful HTTP response from `/flags?v=2`.
- `featureFlags` is a validated immutable evaluator ready for local reads.
- Apps can access `featureFlags.snapshot` directly for explicit app-owned caching; v1 does not add a shortcut property.
- `requestID` maps PostHog `requestId` when present.
- `isPartial` maps PostHog `errorsWhileComputingFlags`. When `true`, `featureFlags` contains returned values but the evaluation may be incomplete.
- `quotaLimits` maps PostHog `quotaLimited`.
- Do not add a public initializer in v1. This result is SDK-produced; tests, examples, and apps should construct `FeatureFlags` directly when they need local fixtures.

### 5.11 `PostHogFeatureFlagClient`

```swift
public final class PostHogFeatureFlagClient: Sendable {
    public let configuration: PostHogFeatureFlagConfiguration

    public init(configuration: PostHogFeatureFlagConfiguration) throws

    public func evaluateFeatureFlags(
        for context: PostHogFeatureFlagContext
    ) async throws -> PostHogFeatureFlagEvaluation
}
```

Rules:

- Public facade and resource owner for PostHog feature flag evaluation.
- Initializer validates configuration, creates reusable internal transport, and must not perform network or filesystem I/O.
- `evaluateFeatureFlags(for:)` performs one cancellable HTTP POST to `/flags?v=2` using `configuration.requestTimeout`.
- The method validates the supplied context before making the request.
- The method preserves cancellation and must not convert `CancellationError` into a package error.
- The method returns the flags PostHog provided and sets `isPartial == true` when PostHog returns `errorsWhileComputingFlags == true`.
- The method returns quota metadata when PostHog returns `quotaLimited`.
- No public close method, refresh loop, task handle, stream, or callback API exists in v1.

### 5.12 `PostHogFeatureFlagError`

```swift
public enum PostHogFeatureFlagError: Error, Sendable, Hashable, CustomStringConvertible {
    case invalidConfiguration(String)
    case invalidInput(String)
    case unexpectedStatusCode(Int)
    case transportFailure(String)
    case invalidResponse(String)
    case invalidFeatureFlagSnapshot(FeatureFlagError)

    public var description: String { get }
}
```

Rules:

- Used for package-owned failure categories.
- `invalidInput` is used for malformed evaluation request inputs supplied to `evaluateFeatureFlags(for:)`.
- Low-level non-Sendable errors must not be exposed as associated values.
- Cancellation is preserved as cancellation, not wrapped in `transportFailure`.
- `invalidFeatureFlagSnapshot` is used when PostHog response data maps to a `FeatureFlagSnapshot` rejected by `GraphitFeatureFlags` validation.
- Error descriptions must not include raw project tokens, distinct IDs, group IDs, custom runtime User-Agent text, full request bodies, or raw response bodies.

---

## 6. PostHog `/flags?v=2` behavior

### 6.1 Request

V1 sends:

```http
POST {host}/flags?v=2
Content-Type: application/json
Accept: application/json
User-Agent: {runtime-derived package default or custom runtime User-Agent}
```

Request body:

```json
{
  "api_key": "<ph_project_token>",
  "distinct_id": "user-123",
  "groups": {
    "company": "graphit"
  },
  "evaluation_contexts": ["production", "ios"]
}
```

Rules:

- Use `api_key`, not the legacy `token` spelling, for the project token.
- Apply `configuration.requestTimeout` to the one HTTP request.
- Include `groups` only when at least one group is provided.
- Encode `groups` from validated group entries sorted by group `type`; duplicate group types are rejected before encoding.
- Include `evaluation_contexts` only when at least one evaluation context tag is provided.
- Encode `evaluation_contexts` sorted by tag raw value for deterministic requests.
- Do not include `config=true` in v1.
- Do not include person properties, group properties, GeoIP override headers, event data, or analytics properties in v1.
- Do not include credentials, raw distinct IDs, raw group values, custom runtime User-Agent text, or request bodies in logs.

### 6.2 Response fields consumed by v1

The implementation consumes only the fields needed for feature flag evaluation:

```json
{
  "flags": {
    "my-awesome-flag": {
      "key": "my-awesome-flag",
      "enabled": true,
      "variant": "treatment"
    }
  },
  "errorsWhileComputingFlags": false,
  "quotaLimited": ["feature_flags"],
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

Rules:

- Unknown top-level and per-flag fields are ignored.
- `flags` missing or not an object is an invalid response.
- Per-flag `enabled` missing or not a Boolean is an invalid response.
- When `enabled == true`, per-flag `variant` may be missing, `null`, or a string. Other shapes are invalid.
- When `enabled == false`, any `variant` field is ignored regardless of shape.
- Per-flag `key` may be used as a consistency check. If present and different from the dictionary key, treat the response as invalid.
- `requestId` is optional.
- `errorsWhileComputingFlags` defaults to `false` when absent.
- `quotaLimited` defaults to an empty set when absent.

### 6.3 Mapping rules

For each PostHog flag entry:

| PostHog fields | Graphit value |
| --- | --- |
| `enabled: false` | `FeatureFlag.disabled(key)` |
| `enabled: true`, no `variant` | `FeatureFlag.enabled(key)` |
| `enabled: true`, `variant: null` | `FeatureFlag.enabled(key)` |
| `enabled: true`, string `variant` | `FeatureFlag.variant(key, FeatureFlagVariant(variant))` |

Rules:

- A string variant implies enabled behavior only when `enabled == true`.
- If `enabled == false`, any variant field is ignored and the value maps to `.disabled`.
- `variant: null` is treated as no variant.
- An empty string variant is not normalized away; it maps to a variant and can be rejected by `GraphitFeatureFlags` validation.
- Holdout variants such as `holdout-727` are preserved as normal string variants.
- PostHog `reason`, `metadata`, and `metadata.payload` are ignored in v1.
- Sort PostHog flag entries by dictionary key before building `FeatureFlagSnapshot` so snapshots, tests, examples, and optional app caching are deterministic.
- Mapped keys and variants are semantically validated by constructing `FeatureFlags`.

---

## 7. Caching and state guidance

### 7.1 Base provider has no cache

The base v1 provider does not persist snapshots or define stale behavior. It is an explicit evaluation and mapping SDK, not a cache or state owner.

It must not silently avoid or perform network calls based on time, previous results, app lifecycle, or global state. Apps that want caching load, validate, replace, persist, expire, and discard snapshots according to app-owned policy.

### 7.2 Recommended app-owned cache flow

Apps that need lower latency, offline startup, or lower PostHog usage can cache `FeatureFlagSnapshot` explicitly:

```swift
// 1. Load cached snapshot from app-owned storage.
let cachedSnapshot = try JSONDecoder().decode(FeatureFlagSnapshot.self, from: cachedData)
var currentFlags = try FeatureFlags(snapshot: cachedSnapshot)

// 2. Refresh explicitly when the app decides it is appropriate.
let evaluation = try await client.evaluateFeatureFlags(for: context)
currentFlags = evaluation.featureFlags

// 3. Persist the new snapshot explicitly when app policy accepts the result.
if !evaluation.isPartial {
    let data = try JSONEncoder().encode(evaluation.featureFlags.snapshot)
    try await cacheBucket.setData(data, for: CacheKey("posthog-flags:user-123"))
}
```

The cache key and invalidation policy are app-owned. A correct cache key must account for the evaluation inputs that affect PostHog results, such as host, project, distinct ID, groups, evaluation contexts, and runtime policy. The package does not define that key because it may contain private identifiers and app-specific privacy decisions.

Cache `FeatureFlagSnapshot` when persistence is needed, not `PostHogFeatureFlagEvaluation`. The evaluation result is SDK-produced request metadata plus the mapped `FeatureFlags` value.

### 7.3 Future caching adapter

A future package or target may add an explicit caching adapter, possibly depending on GraphitCache:

```swift
let cached = PostHogCachedFeatureFlags(
    client: client,
    cache: cacheBucket,
    policy: .ttl(.minutes(5), staleOnFailure: true)
)
```

That is not v1. Do not add placeholder public cache types now.

---

## 8. Concurrency and cancellation

- Public values are `Sendable` where possible.
- Public facade is a resource-owning `final class` and is not `@MainActor`.
- No work runs on the main actor by design.
- Network work uses structured async APIs.
- No `Task.detached`.
- No unowned background tasks.
- No internal refresh loop.
- Check cancellation at natural boundaries before request construction, after transport returns, and before decoding/mapping when practical.
- Preserve `CancellationError` or URLSession cancellation semantics.
- Internal mutable state, if any, must be owned by a narrow object or actor with a clear lifetime. V1 should need little or no mutable state beyond the package-owned reusable Foundation transport owned by the client.

---

## 9. Internal architecture

V1 internals should stay small:

```text
PostHogFeatureFlagClient
  ├─ validated configuration
  ├─ internal HTTP transport
  ├─ request builder
  ├─ response decoder
  └─ mapper to FeatureFlags
```

Suggested source tree:

```text
Sources/GraphitFeatureFlagsPostHog/
  PostHogFeatureFlagClient.swift
  PostHogFeatureFlagConfiguration.swift
  PostHogEvaluationRuntime.swift
  PostHogFeatureFlagContext.swift
  PostHogFeatureFlagEvaluation.swift
  PostHogFeatureFlagError.swift
  PostHogTextValues.swift
  PostHogValidation.swift
  Internal/
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
```

Rules:

- No public transport protocol in v1.
- No `URLSession.shared` for normal v1 requests; use a package-owned reusable internal session or transport.
- Internal test doubles are allowed for deterministic boundary tests.
- No generated client.
- No vendor SDK import.
- No GraphitCache import.
- No UI framework import.
- No logging by default.
- No raw response body retention.

---

## 10. Validation rules

Validation should reject malformed caller inputs before network work when possible.

### 10.1 Text validation

Project token, distinct ID, group type, group ID, evaluation context tag, and custom runtime User-Agent text must be:

- non-empty after no implicit trimming;
- free of Unicode control scalars;
- within the v1 length limit for that field.

V1 length limits:

| Field | Maximum length |
| --- | ---: |
| Project token | 512 characters |
| Distinct ID | 1,024 characters |
| Group type | 256 characters |
| Group ID | 1,024 characters |
| Evaluation context tag | 256 characters |
| Custom runtime User-Agent | 512 characters |

Control scalars include C0 controls, DEL, and C1 controls:

```text
scalar.value <= 0x1F || scalar.value == 0x7F || (0x80...0x9F).contains(scalar.value)
```

Do not trim, normalize, lowercase, or otherwise rewrite caller-provided text.

### 10.2 Host validation

Host URL must:

- use `http` or `https` scheme;
- include a host;
- not include a query string;
- not include a fragment;
- not include user info;
- use an empty path or `/` in v1.

Production examples should use HTTPS. HTTP is allowed only so local and self-hosted development can be tested intentionally.

### 10.3 Context validation

Evaluation context validation must reject:

- empty distinct ID;
- invalid group type or ID;
- duplicate group types;
- invalid evaluation context tag.

An empty `groups` array is valid. An empty `evaluationContexts` set is valid.

### 10.4 Runtime and timeout validation

Runtime validation must reject:

- empty custom runtime User-Agent text;
- custom runtime User-Agent text containing Unicode control scalars;
- custom runtime User-Agent text longer than 512 characters.

`requestTimeout` validation must reject zero or negative durations. V1 does not expose retry policy; callers retry by explicitly calling `evaluateFeatureFlags(for:)` again if their app policy allows it.

---

## 11. Error and failure semantics

### 11.1 Invalid configuration

Thrown by `PostHogFeatureFlagClient.init(configuration:)` when configuration cannot produce valid requests.

Examples:

- empty project token;
- invalid host URL;
- invalid custom runtime User-Agent;
- zero or negative request timeout.

### 11.2 Invalid input

`invalidInput` is thrown by `evaluateFeatureFlags(for:)` before networking when request context is invalid.

Examples:

- empty distinct ID;
- duplicate group types;
- empty group ID;
- empty evaluation context tag.

### 11.3 Transport failure

Represents network or request execution failure after cancellation has been preserved. Request timeout failures are reported through this category with a sanitized timeout-oriented message.

The associated message must be sanitized and must not include credentials, request body, full URL with sensitive query data, raw distinct ID, raw groups, raw custom User-Agent text, or raw response bodies.

### 11.4 Unexpected status code

Non-2xx HTTP status codes throw `unexpectedStatusCode(statusCode)`.

If PostHog later documents useful structured error bodies for `/flags`, mapping can be revisited. V1 does not expose raw error responses.

### 11.5 Invalid response

Malformed JSON, missing required fields, mismatched flag keys, or unsupported response shapes throw `invalidResponse`.

### 11.6 Invalid feature flag snapshot

If PostHog returns keys or variants that cannot be accepted by `GraphitFeatureFlags` validation, throw `invalidFeatureFlagSnapshot` with the underlying `FeatureFlagError`.

---

## 12. Testing strategy

Use Swift Testing for v1 behavior tests. No ordinary test should use the real network.

High-signal tests:

1. configuration accepts US/EU hosts and rejects invalid custom hosts;
2. project token, runtime, custom runtime User-Agent, and request timeout validation;
3. context validation for distinct ID, groups, duplicate group types, and evaluation context tags;
4. request construction uses POST, `/flags`, `v=2`, `api_key`, `distinct_id`, optional sorted `groups`, and optional sorted `evaluation_contexts`;
5. `.client` runtime sends a PostHog-recognizable client runtime User-Agent marker;
6. custom runtime sends the configured custom User-Agent without exposing it in error descriptions;
7. initializer does not call transport;
8. one evaluation call performs one transport call;
9. request timeout is applied to the one evaluation request;
10. maps disabled, enabled, missing variant, null variant, string variant, and holdout variant flags correctly;
11. maps PostHog flag objects in deterministic key order;
12. ignores any variant shape for `enabled: false` responses;
13. ignores PostHog metadata, reason, and payload fields;
14. returns partial results with `isPartial == true` when `errorsWhileComputingFlags` is true;
15. returns quota metadata when `quotaLimited` includes `feature_flags`;
16. tolerates unknown quota-limit categories;
17. rejects malformed responses and mismatched per-flag keys;
18. preserves cancellation;
19. sanitizes public error descriptions;
20. README examples compile.

Test support rules:

- Use internal fake transport; do not add public testing products.
- Do not create protocols only for mocks in public API.
- Keep fixtures small but realistic.
- Avoid sleeps; use explicit fake transport synchronization for cancellation tests.
- Tests must be deterministic and parallel-safe.

---

## 13. Documentation requirements

README should include:

- installation;
- relationship to `GraphitFeatureFlags`;
- quick start;
- explicit update flow by replacing app-owned `FeatureFlags`;
- runtime filtering note explaining semantic runtime policy and the default `.client` runtime;
- request timeout configuration;
- no-network-on-init guarantee;
- caching guidance and why caching is app-owned in v1;
- quota/partial-result metadata;
- error and cancellation notes;
- no analytics/exposure tracking note;
- examples that compile.

Public documentation comments must cover:

- purpose;
- parameters;
- return values;
- thrown errors;
- cancellation behavior for async APIs;
- ownership and state replacement;
- privacy notes for project tokens, distinct IDs, groups, and custom runtime User-Agent text.

---

## 14. Deferred decisions and non-goals

Do not add placeholder public APIs for these areas in v1.

### 14.1 PostHog admin and management APIs

Deferred:

- feature-flag CRUD;
- list/retrieve/update/delete admin endpoints;
- personal API keys;
- project IDs;
- activity APIs;
- dashboard/status/version APIs;
- local evaluation admin endpoint.

Reason: this package is for app/runtime flag evaluation, not PostHog administration.

### 14.2 Local evaluation

Deferred:

- `/api/projects/:project_id/feature_flags/local_evaluation/`;
- personal API key scope handling;
- local rule engine;
- cohort support;
- property matching;
- rollout bucketing.

Reason: local evaluation is a larger product with different authentication, data model, caching, and correctness requirements.

### 14.3 Advanced evaluation inputs

Deferred:

- person property overrides (`person_properties`), which supply temporary person/user attributes such as plan, country, or beta status for this evaluation only;
- group property overrides (`group_properties`), which supply temporary attributes for groups listed in `groups`, such as account tier or organization status;
- GeoIP override headers such as `HTTP_X_FORWARDED_FOR`, which ask PostHog to derive GeoIP properties from a supplied client IP address;
- arbitrary JSON request values.

Reason: these are useful when PostHog's stored properties are missing or stale, but they require a package-owned JSON value model, privacy review, cache-key policy, error redaction, and more validation. Do not add `[String: Any]` or raw JSON dictionaries as public API.

### 14.4 Caching and refresh stores

Deferred:

- built-in cache;
- GraphitCache dependency;
- cache key policy;
- TTL/stale policy;
- stale-on-failure behavior;
- background refresh;
- refresh timers;
- app lifecycle integration;
- mutable feature flag store;
- observation stream.

Reason: apps own state, privacy, lifecycle, and cost policy in v1. Base provider remains explicit and cache-friendly.

### 14.5 Analytics and exposure tracking

Deferred:

- `$feature_flag_called` capture;
- event property helpers;
- exposure deduplication;
- event batching;
- event retry;
- PostHog event ingestion client.

Reason: local reads must remain side-effect-free. Analytics policy is separate from fetching resolved flag values.

### 14.6 UI adapters and syntax sugar

Deferred:

- SwiftUI/UIKit/AppKit adapters;
- Observation or `ObservableObject` stores;
- property wrappers;
- macros;
- dynamic member lookup;
- global environment values.

Reason: the package should stay explicit and framework-neutral.

### 14.7 First-class server runtime support

Deferred:

- semantic `.server` runtime mode;
- Swift server User-Agent policy;
- Linux support claim and CI;
- server framework adapters.

Reason: server-side Swift support should be designed explicitly around a stable PostHog runtime signal and tested supported platforms, not inferred from accidental headers. V1 keeps the public runtime model extensible with `.client` and `customUserAgent(_:)`.

### 14.8 Remote config and payloads

Deferred:

- PostHog `metadata.payload` mapping;
- typed payload decoding;
- encrypted payload handling;
- remote configuration APIs.

Reason: GraphitFeatureFlags v1 models only disabled, enabled, and string variant values.

---

## 15. Engineering quality bar

- Swift 6 language mode.
- iOS 18+ and macOS 15+ package floor.
- One public product: `GraphitFeatureFlagsPostHog`.
- Depends on `GraphitFeatureFlags` only.
- No third-party Swift dependencies.
- No GraphitCache dependency in v1.
- Public APIs are documented.
- Public values are `Sendable` where possible.
- No network on initialization.
- No hidden network calls on reads.
- One explicit evaluation call performs at most one PostHog `/flags?v=2` request.
- Default runtime filtering is intentional through semantic `.client` runtime policy and a PostHog-recognizable client User-Agent marker.
- Request timeout is explicit and validated.
- Cancellation is preserved.
- No hidden global mutable state.
- No service locator.
- No public provider protocol before multiple providers prove the common shape.
- No generated or vendor types leak into public API.
- No raw secrets or private identifiers in logs or public error descriptions.
- No caching, persistence, analytics, UI, background tasks, or observation in base v1.
- `PostHogFeatureFlagEvaluation` is SDK-produced and has no public initializer in v1.
- Tests use deterministic fake transport, not real PostHog network calls.

GraphitFeatureFlagsPostHog v1 should be small enough to understand quickly, explicit enough to avoid surprise PostHog usage, and useful enough for apps to compose with their own state, caching, and analytics policies.
