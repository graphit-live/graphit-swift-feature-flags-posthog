# Task 02 — Request construction

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/03_validation_and_redaction.md`
- `implementation/04_request_response_mapping.md`
- `implementation/05_internal_architecture_transport.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/TESTING_QUALITY.md`

## Prereqs

- Task 01 done.

## Implement

- Internal request builder for one `/flags?v=2` evaluation request.
- Endpoint construction from validated host:
  - append `/flags`;
  - query `v=2`;
  - no `config=true`.
- HTTP method `POST`.
- Headers:
  - `Content-Type: application/json`;
  - `Accept: application/json`;
  - `User-Agent` from runtime policy.
- Request body:
  - `api_key` from project token;
  - `distinct_id` from context;
  - optional `groups` object sorted by group `type`;
  - optional `evaluation_contexts` array sorted by raw tag value.
- Apply `requestTimeout` to the one request.
- Keep request type internal.

## Required decisions

- Use `api_key`, not legacy `token`.
- Default User-Agent is exactly `posthog-ios/1.0.0 graphit-sdk/0.1.0` for v0.1.0.
- Default User-Agent must start with `posthog-ios/1.0.0`.
- Custom User-Agent is sent exactly when configured and valid.
- Duplicate group types are rejected before body construction.
- Do not include empty `groups` or `evaluation_contexts`.
- Do not include person properties, group properties, GeoIP override headers, event data, analytics properties, or arbitrary JSON.

## Do not implement

- response decoding/mapping;
- real URLSession execution unless needed as a no-op shell;
- retry/backoff;
- cache behavior;
- logging/instrumentation;
- public request/transport APIs.

## Tests

Add Swift Testing coverage for:

- method, path, query, and headers;
- no `config=true`;
- default User-Agent exact value and prefix;
- custom User-Agent exact value;
- request timeout;
- `api_key` and `distinct_id` body keys;
- no `token` body key;
- omitted optional `groups` and `evaluation_contexts` when empty;
- sorted groups;
- sorted evaluation contexts;
- one evaluation request builds one request shape.

## Verify

```bash
swift build
swift test --filter RequestConstruction
```

## Definition of done

- Internal request builder matches PostHog `/flags?v=2` contract.
- Deterministic body ordering for groups/tags is covered.
- Sensitive request data is not logged or surfaced in errors.
