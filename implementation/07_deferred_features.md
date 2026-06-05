# Deferred features and non-goals

Do not add placeholders for deferred features in v1. Public API should stay exactly aligned with `Spec.md`.

## Provider abstractions

Deferred:

- `FeatureFlagProvider`, `PostHogProvider`, `FeatureFlagSource`, or similar protocols;
- provider registry;
- service locator;
- public transport protocol;
- public testing helper product.

Reason: v1 is one concrete PostHog adapter. Shared provider shape should wait until multiple real providers prove the common contract.

## PostHog admin and management APIs

Deferred:

- feature-flag CRUD;
- list/retrieve/update/delete admin endpoints;
- personal API keys;
- project IDs;
- activity APIs;
- dashboard/status/version APIs;
- local evaluation admin endpoint.

Reason: this package is for runtime flag evaluation, not PostHog administration.

## Local evaluation

Deferred:

- local rule engine;
- `/api/projects/:project_id/feature_flags/local_evaluation/`;
- personal API key scope handling;
- cohorts;
- property matching;
- rollout bucketing.

Reason: local evaluation is a larger product with different authentication, caching, data-model, and correctness requirements.

## Advanced evaluation inputs

Deferred:

- person property overrides;
- group property overrides;
- GeoIP override headers;
- arbitrary JSON request values;
- public JSON value model.

Reason: these require privacy review, cache-key policy, redaction policy, validation, and a package-owned JSON value model. Do not add `[String: Any]` or raw JSON dictionaries as public API.

## Caching and refresh stores

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

Reason: apps own state, privacy, lifecycle, quota/cost policy, and stale behavior in v1. Base provider remains explicit and cache-friendly.

## Analytics and exposure tracking

Deferred:

- `$feature_flag_called` capture;
- event property helpers;
- exposure deduplication;
- event batching;
- event retry;
- PostHog event ingestion client;
- automatic logging or metrics.

Reason: local reads must remain side-effect-free. Analytics policy is separate from fetching resolved flag values.

## UI adapters and syntax sugar

Deferred:

- SwiftUI/UIKit/AppKit adapters;
- Observation or `ObservableObject` stores;
- property wrappers;
- macros;
- dynamic member lookup;
- global environment values;
- `PostHogFeatureFlagClient.shared`.

Reason: the package should stay explicit and framework-neutral.

## First-class server runtime support

Deferred:

- semantic `.server` runtime mode;
- Swift server User-Agent policy;
- Linux support claim and CI;
- server framework adapters.

Reason: server-side Swift support should be designed around a stable PostHog runtime signal and tested supported platforms, not inferred from accidental headers.

## Remote config and payloads

Deferred:

- PostHog `metadata.payload` mapping;
- typed payload decoding;
- encrypted payload handling;
- remote configuration APIs.

Reason: `GraphitFeatureFlags` v1 models only disabled, enabled, and string variant values.

## Retry/backoff and resilience policy

Deferred:

- public retry policy;
- automatic retry;
- circuit breakers;
- stale-on-failure policy;
- timeout backoff;
- rate-limit handling beyond surfacing quota metadata.

Reason: v1 keeps network behavior explicit. Callers can retry by calling `evaluateFeatureFlags(for:)` again according to app policy.
