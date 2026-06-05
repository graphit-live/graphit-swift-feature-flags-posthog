# Testing strategy

Goal: prove behavior that callers and maintainers care about. Avoid vanity coverage and implementation trivia.

## Frameworks

- Use Swift Testing for v1 behavior tests.
- No ordinary test should use the real network.
- Tests may import `Foundation`, `GraphitFeatureFlags`, and `GraphitFeatureFlagsPostHog`.
- No XCTest required in v1 unless a future performance lane is added.
- No sleeps; use fake transport synchronization for cancellation and suspension tests.

## Test support

Use internal test doubles under `Tests/GraphitFeatureFlagsPostHogTests/Support`.

Suggested fake transport capabilities:

- records every request;
- returns configured status/data;
- throws configured errors;
- can suspend until explicitly resumed for cancellation tests;
- is parallel-safe or constructed per test.

Do not add a public `GraphitFeatureFlagsPostHogTesting` product in v1.

## Suites

### Configuration validation tests

Cover:

- US and EU built-in hosts;
- valid local/self-hosted custom hosts;
- invalid host schemes, missing host, query, fragment, user info, and non-root paths;
- project token validation;
- default runtime validation;
- custom User-Agent validation;
- positive timeout validation;
- no network on initializer.

### Context validation tests

Cover:

- valid distinct ID only;
- optional groups;
- duplicate group type rejection;
- invalid group type/ID text;
- optional evaluation context tags;
- invalid tag text;
- empty groups and empty evaluation context set are valid.

### Request construction tests

Cover:

- `POST` method;
- `/flags` path;
- `v=2` query;
- no `config=true`;
- `Content-Type: application/json`;
- `Accept: application/json`;
- default User-Agent exactly `posthog-ios/1.0.0 graphit-sdk/0.1.0`;
- default User-Agent starts with `posthog-ios/1.0.0`;
- custom User-Agent sent exactly as configured;
- body uses `api_key` and `distinct_id`;
- no legacy `token` field;
- groups omitted when empty;
- groups sorted by type when present;
- evaluation contexts omitted when empty;
- evaluation contexts sorted by raw value when present;
- timeout applied to the one request.

### Response mapping tests

Cover:

- disabled flags;
- enabled flags with missing variant;
- enabled flags with `variant: null`;
- enabled flags with string variant;
- holdout variants preserved;
- disabled flags ignore any variant shape;
- metadata/reason/payload ignored;
- deterministic key ordering in mapped snapshot;
- `errorsWhileComputingFlags` maps to `isPartial`;
- `quotaLimited` maps known and unknown quota categories;
- absent optional metadata defaults correctly;
- malformed responses and mismatched keys throw `invalidResponse`;
- invalid mapped keys/variants throw `invalidFeatureFlagSnapshot`.

### Client evaluation tests

Cover:

- initializer does not call transport;
- one evaluation call performs one transport call;
- successful end-to-end fake transport response returns `FeatureFlags`;
- non-2xx status throws `unexpectedStatusCode`;
- transport failure throws sanitized `transportFailure`;
- invalid context throws before transport;
- cancellation before request avoids transport;
- cancellation during suspended transport is preserved;
- cancellation after transport return and before decode/map is preserved where practical.

### Error/redaction tests

Cover:

- `description` for token, distinct ID, group, and custom runtime does not reveal raw text;
- public error descriptions do not reveal raw project token, distinct ID, group ID, custom User-Agent, request body, or raw response body;
- low-level error messages are sanitized.

### README example tests

Cover:

- quick start compiles;
- explicit update-by-replacement flow compiles;
- partial/quota metadata example compiles if included;
- app-owned caching example uses `FeatureFlagSnapshot`, not provider metadata.

## Minimal verification commands

```bash
swift package describe
swift build
swift build -c release
swift test
```

Useful focused filters after tests exist:

```bash
swift test --filter ConfigurationValidation
swift test --filter ContextValidation
swift test --filter RequestConstruction
swift test --filter ResponseMapping
swift test --filter ClientEvaluation
swift test --filter Cancellation
swift test --filter READMEExamples
```

## Quality bar per test

- Proves public behavior or a meaningful internal boundary.
- Deterministic input and assertions.
- No real network.
- No wall-clock sleeps.
- Parallel-safe by default.
- Clear failure assertions.
- Avoid exact error-message assertions except redaction and intentionally locked default User-Agent/version scenarios.

## Do not add

- public test helpers;
- protocols only for public mocks;
- broad mock frameworks;
- real PostHog credentials;
- real network tests;
- cache/storage fixtures;
- sleeps as synchronization;
- tests for private implementation trivia that does not affect behavior.
