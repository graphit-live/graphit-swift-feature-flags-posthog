# GraphitFeatureFlagsPostHog implementation plan

Purpose: implement the minimal v1 described by `Spec.md` Draft 4. V1 is an explicit PostHog `/flags?v=2` feature-flag evaluation adapter for `GraphitFeatureFlags`. It maps PostHog responses into immutable `FeatureFlags` values and does not own app state, refresh cadence, caching, analytics, exposure tracking, or UI integration.

## Source order

1. `AGENTS.md`: engineering standard.
2. Relevant `.agents/*` companion guides.
3. `Spec.md`: product/API contract.
4. `docs/posthog-docs.md`: captured PostHog endpoint/runtime behavior.
5. `implementation/*.md`: implementation notes.
6. `implementation/tasks/*.md`: vertical implementation slices.

## Local docs map

- `00_decisions.md`: locked minimal-v1 decisions and default User-Agent policy.
- `01_package_layout.md`: SwiftPM manifest, source tree, imports, access control, and dependency rules.
- `02_public_api_contract.md`: exact public API contract; no extra public symbols without alignment.
- `03_validation_and_redaction.md`: semantic validation, timing, text limits, and sanitized descriptions/errors.
- `04_request_response_mapping.md`: PostHog request construction, response decoding, and mapping into `GraphitFeatureFlags`.
- `05_internal_architecture_transport.md`: client ownership, internal transport seam, cancellation, and error mapping.
- `06_testing_strategy.md`: high-signal deterministic Swift Testing plan.
- `07_deferred_features.md`: non-goals that must not leak into v1.
- `tasks/*.md`: behavior-first implementation slices.

## Global task protocol

Before task:

- read this file, `00_decisions.md`, relevant design docs, the task file, `Spec.md`, and companion guides;
- check `swift --version`; require Swift 6.3.x;
- check `git status --short`; do not overwrite unrelated work.

During task:

- implement one vertical behavior slice at a time;
- add public documentation comments as public symbols are introduced;
- keep the public v1 surface to the types in `Spec.md`;
- keep PostHog transport/request/response shapes internal;
- keep runtime filtering intentional with the default User-Agent starting with `posthog-`;
- do not add provider protocols, caching, persistence, GraphitCache, analytics, exposure tracking, UI adapters, globals, refresh loops, background tasks, generated clients, vendor SDK imports, or public testing products;
- if reality shifts from task/spec: stop, document the delta, and align before coding through it.

After task:

- run verification commands listed in the task;
- leave explicit follow-up notes in planning docs when needed; do not hide TODOs in code.

## Default User-Agent policy

For the first release, the default `.client` runtime User-Agent is locked as:

```text
posthog-ios/1.0.0 graphit-sdk/0.1.0
```

Rules:

- The string must start with `posthog-ios/1.0.0` so PostHog's runtime parser sees the PostHog SDK marker at the beginning of the full User-Agent.
- `posthog-ios/1.0.0` is a stable PostHog runtime marker, not a claim that this package embeds the PostHog iOS SDK.
- `graphit-sdk/<version>` is the Graphit package marker. Before each release tag, update/check this value to match the tag without the leading `v`.
- Do not reorder the tokens.
- Do not use `graphit-sdk/... posthog-ios/...` because PostHog's parser does not scan later tokens for the SDK marker.
- Do not use `posthog-ios/graphit-sdk/...` because that makes the parsed PostHog SDK version non-conventional.

## Why vertical slices

This package should share GraphitCache's engineering posture, not its storage complexity. Build public behavior first, then internal request/response and transport behavior. The implementation should remain a small concrete adapter with deterministic tests and replaceable internals behind a stable package-owned public API.
