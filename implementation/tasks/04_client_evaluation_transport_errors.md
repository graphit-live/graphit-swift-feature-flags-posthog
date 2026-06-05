# Task 04 — Client evaluation, transport, errors, and cancellation

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/05_internal_architecture_transport.md`
- `implementation/04_request_response_mapping.md`
- `implementation/03_validation_and_redaction.md`
- `.agents/SWIFT_CONCURRENCY_6_3.md`
- `.agents/TESTING_QUALITY.md`

## Prereqs

- Task 03 done.

## Implement

- Production internal HTTP transport using a package-owned reusable `URLSession`.
- Prefer `URLSessionConfiguration.ephemeral`.
- `PostHogFeatureFlagClient.evaluateFeatureFlags(for:)` end-to-end flow:
  - preserve cancellation;
  - validate context before networking;
  - build request;
  - execute one transport call;
  - map non-2xx status to `unexpectedStatusCode`;
  - decode/map successful response;
  - return `PostHogFeatureFlagEvaluation`.
- Internal fake transport support for tests via `@testable import` or test-only initializer if needed and not public.
- Sanitized transport failure mapping.
- Cancellation preservation for pre-request, during transport, and after transport return where practical.

## Required decisions

- Initializer performs no network or filesystem I/O.
- One evaluation call performs at most one transport call.
- No `URLSession.shared` for normal v1 requests.
- No retry/backoff in v1.
- No fire-and-forget tasks.
- No `Task.detached`.
- No public close method.
- No public transport API.
- Cancellation is not wrapped in `PostHogFeatureFlagError`.
- Low-level errors are not exposed as associated values.

## Do not implement

- caching/stale fallback;
- background refresh;
- observation streams;
- analytics/exposure events;
- logging/instrumentation;
- UI adapters;
- GraphitCache integration;
- server runtime mode.

## Tests

Add Swift Testing coverage for:

- initializer does not call fake transport;
- successful evaluation through fake transport;
- one evaluation call records one transport call;
- invalid context throws before transport;
- non-2xx status throws `unexpectedStatusCode`;
- transport failure throws sanitized `transportFailure`;
- malformed successful response throws `invalidResponse`;
- invalid mapped snapshot throws `invalidFeatureFlagSnapshot`;
- cancellation before request avoids transport;
- cancellation during suspended fake transport is preserved;
- no raw token/distinct ID/group/custom User-Agent/request body/raw response body appears in errors.

## Verify

```bash
swift build
swift test --filter ClientEvaluation
swift test --filter ErrorMapping
swift test --filter Cancellation
swift test
```

## Definition of done

- Public client performs explicit, cancellable, one-request evaluations.
- Internal URLSession transport is reusable and owned by the client.
- Tests use fake transport; no real network.
- Error mapping and redaction match spec.
- No concurrency warnings.
