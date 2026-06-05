# Task 00 — Bootstrap package and API shell

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/01_package_layout.md`
- `implementation/02_public_api_contract.md`
- `.agents/PACKAGE_RELEASE.md`
- `.agents/PUBLIC_API_DESIGN.md`

## Prereqs

- `swift --version` shows 6.3.x.
- `git status --short` reviewed; no unrelated overwrite.

## Implement

- Create `Package.swift` with tools version 6.3.
- Platforms: `.iOS(.v18)`, `.macOS(.v15)`.
- Public product: `GraphitFeatureFlagsPostHog` only.
- Dependency: `GraphitFeatureFlags` only.
- Targets: `GraphitFeatureFlagsPostHog`, `GraphitFeatureFlagsPostHogTests`.
- Swift language mode 6 for both targets.
- Add compile-ready public API declarations matching `Spec.md`:
  - `PostHogProjectToken`;
  - `PostHogDistinctID`;
  - `PostHogHost`;
  - `PostHogEvaluationRuntime`;
  - `PostHogGroup`;
  - `PostHogEvaluationContextTag`;
  - `PostHogFeatureFlagContext`;
  - `PostHogFeatureFlagConfiguration`;
  - `PostHogQuotaLimit`;
  - `PostHogFeatureFlagEvaluation`;
  - `PostHogFeatureFlagClient`;
  - `PostHogFeatureFlagError`.
- Add public documentation comments for every public symbol introduced.
- Keep `PostHogFeatureFlagEvaluation` without a public initializer.
- Add smoke tests only as needed for test discovery.

## Do not implement

- request construction behavior;
- response mapping behavior;
- URLSession transport behavior;
- provider abstractions;
- caching/persistence;
- GraphitCache integration;
- analytics/exposure tracking;
- UI/platform adapters;
- property wrappers/macros/dynamic member lookup;
- global/shared client;
- public transport or public testing product;
- behavior beyond minimal placeholders needed to compile.

## Verify

```bash
swift package describe
swift build
swift test
```

## Definition of done

- Package resolves/builds/tests empty or smoke suite.
- Public API shape matches `Spec.md`.
- No extra public types.
- No UI/vendor/GraphitCache imports.
- No network on initialization.
