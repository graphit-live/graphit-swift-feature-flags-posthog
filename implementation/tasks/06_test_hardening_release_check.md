# Task 06 — Test hardening and release check

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/06_testing_strategy.md`
- `implementation/07_deferred_features.md`
- `.agents/TESTING_QUALITY.md`
- `.agents/SWIFT_CONCURRENCY_6_3.md`
- `.agents/PACKAGE_RELEASE.md`

## Prereqs

- Implementation feature-complete.

## Implement/check

- Remove low-value duplicate tests.
- Add missing high-signal tests from `implementation/06_testing_strategy.md`.
- Audit public API for accidental deferred types, protocols, helpers, conveniences, public initializers, or public test hooks.
- Audit imports to ensure no SwiftUI/UIKit/AppKit/Combine/Observation/OSLog/GraphitCache/PostHog SDK/third-party imports.
- Audit for accidental globals, singleton state, service locators, task-local dependency lookup, property wrappers, macros, dynamic member lookup, provider seams, cache APIs, refresh loops, background tasks, or analytics hooks.
- Confirm ordinary tests use fake transport, not real PostHog network calls.
- Confirm public error descriptions and redacted descriptions do not leak secrets/private identifiers.
- Confirm default User-Agent for v0.1.0 is exactly `posthog-ios/1.0.0 graphit-sdk/0.1.0`.
- Confirm `graphit-sdk/<version>` matches intended release tag without leading `v` before tagging.
- Run debug and release builds.

## Quality gates

- deterministic tests;
- no real network;
- no hidden filesystem dependency beyond normal package/test execution;
- tests parallel-safe by default;
- failures assert public behavior;
- no concurrency warnings;
- no public API outside `Spec.md` without explicit alignment;
- no cancellation wrapping;
- no raw request/response body leakage in errors.

## Verify

```bash
swift package describe
swift build
swift build -c release
swift test
swift test --parallel
```

If `swift test --parallel` exposes a real issue, fix test isolation; do not serialize the whole suite without alignment.

## Definition of done

- Meaningful coverage of handwritten core adapter behavior.
- No concurrency warnings.
- Public API remains exactly the v1 contract.
- Default User-Agent release version policy is checked.
- Known untested risks documented as follow-up.
- Test count justified by regression value, not coverage vanity.
