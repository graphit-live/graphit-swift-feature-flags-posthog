# Internal architecture and transport

V1 internals stay small and concrete:

```text
PostHogFeatureFlagClient
  ├─ validated configuration snapshot
  ├─ internal reusable HTTP transport
  ├─ request builder
  ├─ response decoder
  └─ mapper to FeatureFlags
```

## Public facade ownership

```swift
public final class PostHogFeatureFlagClient: Sendable {
    public let configuration: PostHogFeatureFlagConfiguration

    private let validatedConfiguration: ValidatedPostHogConfiguration
    private let transport: any PostHogHTTPTransport
}
```

The exact private storage can differ, but ownership must remain clear:

- the client owns immutable configuration;
- the client owns reusable internal transport;
- no app state is retained;
- no tasks are started during initialization;
- no network or filesystem I/O happens during initialization.

`PostHogFeatureFlagClient` is not `@MainActor`.

## Internal transport seam

A narrow internal transport seam is allowed for deterministic tests. It must not be public.

Suggested shape:

```swift
internal protocol PostHogHTTPTransport: Sendable {
    func execute(_ request: URLRequest) async throws -> PostHogHTTPTransportResponse
}

internal struct PostHogHTTPTransportResponse: Sendable {
    let statusCode: Int
    let data: Data
}
```

The concrete production transport should create and reuse a package-owned `URLSession`, preferably with `URLSessionConfiguration.ephemeral` so feature-flag evaluation does not persist cookies or URL-cache data by default.

If the compiler rejects `Sendable` for any Foundation stored property, stop and design the smallest safe ownership wrapper. Do not add `@unchecked Sendable` without a written safety argument and focused tests.

## Evaluation flow

`evaluateFeatureFlags(for:)` should follow this shape:

```text
check cancellation
validate context
build request body and URLRequest
check cancellation
await transport.execute(request)
preserve cancellation
map non-2xx status to unexpectedStatusCode
check cancellation
decode response JSON
map response to FeatureFlags and metadata
return PostHogFeatureFlagEvaluation
```

Rules:

- At most one transport call per evaluation.
- No retry/backoff in v1.
- No fire-and-forget work.
- No `Task.detached`.
- No background refresh loop.
- No hidden reads of app state or global config.
- No logging by default.

## Cancellation

Preserve cancellation semantics:

- `Task.checkCancellation()` at natural boundaries;
- let `CancellationError` propagate;
- if URLSession reports cancellation through a cancellation-shaped error, convert only if needed to preserve cancellation behavior, not to `transportFailure`;
- do not wrap cancellation in `PostHogFeatureFlagError`.

Cancellation before the transport call means no network call should be made. Cancellation after transport returns may stop decoding/mapping before returning a value.

## Error mapping

Map failures into `PostHogFeatureFlagError` only after preserving cancellation:

- invalid configuration -> `.invalidConfiguration(String)` from initializer;
- invalid evaluation context -> `.invalidInput(String)` before network;
- non-2xx status -> `.unexpectedStatusCode(Int)`;
- transport failure -> `.transportFailure(String)` with sanitized message;
- malformed JSON or unsupported response shape -> `.invalidResponse(String)`;
- core snapshot validation failure -> `.invalidFeatureFlagSnapshot(FeatureFlagError)`.

Low-level errors should not be exposed as associated values because they may be non-Sendable or contain private request details.

## Request timeout

Apply `configuration.requestTimeout` to the `URLRequest.timeoutInterval` or an equivalent one-request transport timeout.

Do not add global session timeout policy as a substitute for the public per-client setting.

## URLSession policy

Production transport should:

- avoid `URLSession.shared` for normal v1 requests;
- use an internal reusable session owned by the client/transport;
- prefer ephemeral configuration;
- set headers on the request, not in global mutable state;
- not persist cookies or credentials intentionally.

## Reentrancy and state

V1 should need little or no mutable state beyond Foundation transport internals. Avoid actors/locks unless a real mutable state owner appears.

If mutable shared state is added later, name its owner explicitly and test concurrent calls.

## Testability

Tests should use an internal fake transport through `@testable import`, not a public protocol or public testing product.

Fake transport should be able to prove:

- initializer does not execute transport;
- one evaluation executes one transport call;
- request method, URL, headers, body, and timeout are correct;
- non-2xx status mapping;
- transport failures are sanitized;
- cancellation is preserved without sleeps.
