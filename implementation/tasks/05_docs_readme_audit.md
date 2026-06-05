# Task 05 — Public docs and README audit

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/02_public_api_contract.md`
- `implementation/07_deferred_features.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/PACKAGE_RELEASE.md`

## Prereqs

- Public API behavior mostly complete.

## Implement

- Audit/add documentation comments for every public type and public member.
- Create or update root `README.md` with minimal user docs.
- Compile-check examples through tests where practical.
- Add a release-note/checklist reminder for User-Agent versioning:
  - first release default is `posthog-ios/1.0.0 graphit-sdk/0.1.0`;
  - before future tags, update/check only `graphit-sdk/<version>` to match the tag without leading `v`.

## README must mention

- Swift 6.3.x and Swift language mode 6.
- iOS 18+ primary support and macOS 15+ package support.
- No Linux support claim in v1.
- Relationship to `GraphitFeatureFlags`.
- Quick start with explicit `PostHogFeatureFlagClient` construction and one evaluation call.
- No network on init.
- Network work occurs only in `evaluateFeatureFlags(for:)`.
- Updating app state means replacing an app-owned `FeatureFlags` value.
- Default `.client` runtime User-Agent starts with `posthog-ios/1.0.0` for PostHog client-runtime filtering.
- Custom User-Agent is an advanced escape hatch and is redacted from descriptions/errors.
- Request timeout configuration.
- Partial result metadata via `isPartial`.
- Quota metadata via `quotaLimits`.
- Caching guidance: apps cache `FeatureFlagSnapshot` explicitly if needed.
- No GraphitCache dependency in v1.
- No analytics/exposure tracking.
- Error and cancellation notes.
- Privacy/redaction notes for project token, distinct ID, groups, and custom User-Agent.

## Do not implement

- provider protocols;
- GraphitCache integration;
- cache adapter placeholders;
- bundle/file loading helpers;
- observation or UI adapters;
- instrumentation/events;
- public testing helper product;
- public APIs outside the v1 contract.

## Tests

Add/update README example tests for:

- quick start;
- explicit replacement update flow;
- partial/quota metadata if included;
- app-owned `FeatureFlagSnapshot` caching if included;
- no examples requiring deferred APIs.

## Verify

```bash
swift build
swift test --filter READMEExamples
swift test
```

## Definition of done

- Every public symbol has a documentation comment.
- README matches implemented API and minimal-v1 decisions.
- Examples compile.
- README does not imply hidden network calls, automatic refresh, caching, analytics, or UI behavior.
