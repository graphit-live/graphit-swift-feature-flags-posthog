# Locked decisions — minimal PostHog provider v1

Change process: if implementation conflicts with this file or `Spec.md`, stop and align. Do not silently drift.

## Product scope

- Implement `Spec.md` Draft 4 minimal PostHog provider v1.
- V1 is a concrete PostHog-backed feature-flag evaluation adapter for `GraphitFeatureFlags`.
- One explicit evaluation call performs one PostHog `/flags?v=2` HTTP request for one `PostHogFeatureFlagContext`.
- The package maps PostHog results into `FeatureFlags` and returns request metadata for partial/quota cases.
- Initializers validate configuration only and must not perform network or filesystem I/O.
- Reads happen on returned immutable `FeatureFlags` values; this package does not add read-time network behavior.
- Official product focus: iOS 18+.
- Package also supports macOS 15+ for SwiftPM builds/tests and Mac app use.
- No Linux support claim in v1.
- No third-party Swift packages.
- Depends on `GraphitFeatureFlags` only.
- Does not depend on GraphitCache in v1.
- No PostHog vendor SDK import.

## Package

- SwiftPM source package.
- Swift tools version: 6.3.
- Swift language mode: 6.
- Public product: `GraphitFeatureFlagsPostHog` only.
- Targets: `GraphitFeatureFlagsPostHog`, `GraphitFeatureFlagsPostHogTests`.
- Platforms: `.iOS(.v18)`, `.macOS(.v15)`.
- No public testing product in v1.
- No package resources required in v1.

## Public surface

The v1 public SDK surface is exactly these public types:

1. `PostHogProjectToken`
2. `PostHogDistinctID`
3. `PostHogHost`
4. `PostHogEvaluationRuntime`
5. `PostHogGroup`
6. `PostHogEvaluationContextTag`
7. `PostHogFeatureFlagContext`
8. `PostHogFeatureFlagConfiguration`
9. `PostHogQuotaLimit`
10. `PostHogFeatureFlagEvaluation`
11. `PostHogFeatureFlagClient`
12. `PostHogFeatureFlagError`

Do not add extra public types, public protocols, public helpers, public testing products, public adapters, public cache types, or public transport APIs unless the v1 contract is explicitly re-reviewed.

`PostHogFeatureFlagEvaluation` is SDK-produced and has no public initializer in v1.

## Runtime User-Agent

Default `.client` runtime sends exactly this first-release User-Agent:

```text
posthog-ios/1.0.0 graphit-sdk/0.1.0
```

Rules:

- The full string must start with `posthog-`.
- Keep `posthog-ios/1.0.0` stable as the PostHog client-runtime marker.
- Update only `graphit-sdk/<version>` as the Graphit release version changes.
- For a release tag `v0.1.0`, use `graphit-sdk/0.1.0`.
- Tests should assert the exact v0.1.0 default and that it starts with `posthog-ios/1.0.0`.

## Implementation posture

Build in small vertical behavior slices:

1. package and compile-ready public API shell;
2. public values, configuration, validation, and redaction;
3. request construction;
4. response decoding and mapping;
5. client evaluation, internal transport, and error mapping;
6. documentation and README audit;
7. release hardening.

Prefer concrete values, private/internal helpers, and one narrow internal transport seam for deterministic tests. Do not build abstraction layers before behavior needs them.

## Explicit non-behavior

V1 does not include:

- provider protocols or registries;
- PostHog admin APIs or feature-flag CRUD;
- local evaluation;
- generated clients;
- vendor SDK imports;
- retry/backoff policy;
- cache keys, TTLs, stale fallback, persistence, or GraphitCache integration;
- mutable stores, observation streams, callbacks, Combine, SwiftUI, UIKit, AppKit, or Observation adapters;
- automatic `$feature_flag_called` events, exposure tracking, event capture, logging, metrics, or signposts;
- person property overrides, group property overrides, GeoIP override headers, arbitrary JSON public values, or remote-config payloads;
- process-wide singletons, service locators, task-local dependencies, property wrappers, macros, or dynamic member lookup;
- refresh loops, timers, app lifecycle hooks, or unowned background tasks.

## Cancellation and side effects

- `evaluateFeatureFlags(for:)` is cancellable and preserves cancellation.
- No `Task.detached`.
- No fire-and-forget work.
- No network call occurs before `evaluateFeatureFlags(for:)` is called.
- One evaluation call performs at most one transport call.
- Public error descriptions and redacted descriptions must not contain project tokens, distinct IDs, group IDs, custom User-Agent text, request bodies, raw response bodies, or private URLs.
