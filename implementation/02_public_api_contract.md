# Public API contract

All public declarations require documentation comments. Public values are `Sendable` where specified. Do not add public symbols outside this contract without explicit alignment.

## `PostHogProjectToken`

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
- Client construction validates non-empty text, no control scalars, and length <= 512 characters.
- `description` is redacted and must not include the raw token.

## `PostHogDistinctID`

```swift
public struct PostHogDistinctID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Represents one PostHog `distinct_id` for an evaluation request.
- Construction is nonvalidating.
- Evaluation validates non-empty text, no control scalars, and length <= 1,024 characters.
- `description` is redacted because distinct IDs may contain private user identifiers.

## `PostHogHost`

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
- `.usCloud` is `https://us.i.posthog.com`.
- `.euCloud` is `https://eu.i.posthog.com`.
- Construction is nonvalidating.
- Client construction validates URL shape.
- V1 builds the endpoint by appending `/flags` and query `v=2`.

## `PostHogEvaluationRuntime`

```swift
public struct PostHogEvaluationRuntime: Hashable, Sendable, CustomStringConvertible {
    public static let client: PostHogEvaluationRuntime

    public static func customUserAgent(_ userAgent: String) -> PostHogEvaluationRuntime

    public var description: String { get }
}
```

Rules:

- Represents the PostHog runtime signal used for `/flags` runtime filtering.
- `.client` sends the locked default User-Agent `posthog-ios/1.0.0 graphit-sdk/0.1.0` for the first release.
- `customUserAgent(_:)` is an advanced escape hatch.
- Construction is nonvalidating.
- Client construction validates custom User-Agent text.
- `description` must not expose custom User-Agent text.
- Do not add `.server` in v1.

## `PostHogGroup`

```swift
public struct PostHogGroup: Hashable, Sendable, CustomStringConvertible {
    public let type: String
    public let id: String

    public init(type: String, id: String)

    public var description: String { get }
}
```

Rules:

- Represents one PostHog group for group-based flags.
- Construction is nonvalidating.
- Evaluation validates non-empty `type`/`id`, no control scalars, type length <= 256, ID length <= 1,024, and no duplicate group types in one context.
- `description` is redacted because group IDs may contain private organization or tenant identifiers.
- Validated groups are sorted by `type` during request construction.

## `PostHogEvaluationContextTag`

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
- Evaluation validates non-empty text, no control scalars, and length <= 256.
- Values are encoded as `evaluation_contexts` sorted by raw value.

## `PostHogFeatureFlagContext`

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

- Represents all caller-provided inputs for one `/flags?v=2` request.
- Initializer is nonthrowing and does not perform I/O.
- Evaluation validates the context before networking.
- Duplicate group types are rejected instead of silently collapsed.
- Evaluation contexts are set-like filters; order is not meaningful.

## `PostHogFeatureFlagConfiguration`

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
- Client construction validates token, host, runtime, and positive timeout.
- Do not add retry, cache, analytics, or refresh policy to v1 configuration.

## `PostHogQuotaLimit`

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
- Not `Codable` in v1.

## `PostHogFeatureFlagEvaluation`

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
- No public initializer in v1.
- `featureFlags` is a validated immutable evaluator ready for local reads.
- `requestID` maps PostHog `requestId` when present.
- `isPartial` maps `errorsWhileComputingFlags`, defaulting to `false` when absent.
- `quotaLimits` maps `quotaLimited`, defaulting to an empty set when absent.

## `PostHogFeatureFlagClient`

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
- Not `@MainActor`.
- Safe to call from concurrent tasks.
- Initializer validates configuration and creates reusable internal transport; it does not perform network or filesystem I/O.
- `evaluateFeatureFlags(for:)` validates context and performs one cancellable HTTP POST to `/flags?v=2`.
- Cancellation is preserved, not wrapped.
- No public close method, refresh loop, task handle, stream, callback, or transport API exists in v1.

## `PostHogFeatureFlagError`

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
- Low-level non-Sendable errors are not exposed as associated values.
- Cancellation is preserved as cancellation.
- `invalidFeatureFlagSnapshot` wraps `GraphitFeatureFlags` validation errors.
- Error descriptions must be sanitized.
