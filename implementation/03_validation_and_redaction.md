# Validation and redaction

Validation rejects malformed caller input before network work when possible. Construction of small public text values is intentionally nonvalidating; semantic validation happens at client construction or evaluation.

## Text validation

The following fields must be non-empty, contain no Unicode control scalars, and fit within their v1 length limit:

| Field | Maximum length | Validation timing |
| --- | ---: | --- |
| Project token | 512 characters | `PostHogFeatureFlagClient.init` |
| Distinct ID | 1,024 characters | `evaluateFeatureFlags(for:)` before request construction |
| Group type | 256 characters | `evaluateFeatureFlags(for:)` before request construction |
| Group ID | 1,024 characters | `evaluateFeatureFlags(for:)` before request construction |
| Evaluation context tag | 256 characters | `evaluateFeatureFlags(for:)` before request construction |
| Custom runtime User-Agent | 512 characters | `PostHogFeatureFlagClient.init` |

Control scalars include C0 controls, DEL, and C1 controls:

```text
scalar.value <= 0x1F || scalar.value == 0x7F || (0x80...0x9F).contains(scalar.value)
```

Use `String.count` for v1 character limits. Do not trim, normalize, lowercase, redact by mutation, or otherwise rewrite caller-provided text before sending it to PostHog.

## Host validation

Client construction validates `PostHogHost.url`:

- scheme is `http` or `https`;
- host is present;
- query is absent;
- fragment is absent;
- user info is absent;
- path is empty or `/`.

Production examples should use HTTPS. HTTP is allowed for explicit local/self-hosted testing.

Built-in hosts:

- `.usCloud` -> `https://us.i.posthog.com`
- `.euCloud` -> `https://eu.i.posthog.com`

## Runtime validation

`.client` is always valid and resolves to:

```text
posthog-ios/1.0.0 graphit-sdk/0.1.0
```

Custom runtime User-Agent text must be:

- non-empty;
- free of control scalars;
- length <= 512 characters.

Do not expose custom User-Agent text in `description` or public errors.

## Timeout validation

`PostHogFeatureFlagConfiguration.requestTimeout` must be greater than zero.

V1 exposes no retry policy. Callers retry by explicitly calling `evaluateFeatureFlags(for:)` again when their app policy allows it.

## Context validation

Evaluation context validation rejects:

- empty or invalid distinct ID;
- invalid group type or group ID;
- duplicate group types in one context;
- invalid evaluation context tag.

An empty `groups` array is valid. An empty `evaluationContexts` set is valid.

Duplicate group types are rejected rather than collapsed so callers can detect ambiguous input.

## Deterministic normalization

After validation:

- groups are sorted by `type` before request body construction;
- evaluation contexts are sorted by raw value before request body construction;
- response flag entries are sorted by dictionary key before building `FeatureFlagSnapshot`.

Sorting is for deterministic requests, tests, snapshots, and app-owned cache key construction. JSON object order is not a PostHog semantic.

## Redacted descriptions

These descriptions must be redacted:

- `PostHogProjectToken.description`
- `PostHogDistinctID.description`
- `PostHogGroup.description`
- `PostHogEvaluationRuntime.description` for custom User-Agent cases

`PostHogQuotaLimit.description` may expose its raw value because quota categories are provider metadata, not secrets.

`PostHogEvaluationContextTag.description` may expose raw tag text unless product review later treats tags as private. Tags should still not contain secrets in examples.

## Error redaction

`PostHogFeatureFlagError.description` and associated messages must not include:

- raw project tokens;
- raw distinct IDs;
- raw group IDs;
- raw custom User-Agent text;
- full request bodies;
- raw response bodies;
- sensitive URLs;
- low-level error descriptions that include private request details.

Error messages should identify the failing category and help callers repair input, reconfigure, retry, or inspect the response shape without leaking private data.

## Error categories by timing

Client construction throws `invalidConfiguration` for:

- empty/invalid project token;
- invalid host URL;
- invalid custom runtime User-Agent;
- zero or negative request timeout.

Evaluation throws `invalidInput` before networking for:

- empty/invalid distinct ID;
- invalid groups;
- duplicate group types;
- invalid evaluation context tags.

Evaluation throws transport/response/snapshot errors after networking according to `05_internal_architecture_transport.md` and `04_request_response_mapping.md`.

Cancellation is never converted into `PostHogFeatureFlagError`.
