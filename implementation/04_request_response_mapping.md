# Request, response, and mapping

This file defines the internal PostHog boundary. Public callers receive package-owned values and `GraphitFeatureFlags` values, not raw PostHog JSON shapes.

## Request endpoint

V1 sends one request per evaluation:

```http
POST {host}/flags?v=2
Content-Type: application/json
Accept: application/json
User-Agent: {runtime-derived User-Agent}
```

Rules:

- Build the endpoint from the validated `PostHogHost` root.
- Append path `/flags`.
- Add query item `v=2`.
- Do not add `config=true` in v1.
- Apply `configuration.requestTimeout` to this one request.
- Use one HTTP request for the full evaluation context, not one request per flag.

## Default User-Agent

For `.client`, send exactly:

```text
posthog-ios/1.0.0 graphit-sdk/0.1.0
```

The order matters. PostHog's runtime parser checks whether the entire User-Agent starts with `posthog-`; it should see `posthog-ios/1.0.0` as the SDK marker and `graphit-sdk/0.1.0` as extra info.

## Request body

Internal request body shape:

```json
{
  "api_key": "<ph_project_token>",
  "distinct_id": "user-123",
  "groups": {
    "company": "graphit"
  },
  "evaluation_contexts": ["ios", "production"]
}
```

Rules:

- Use `api_key`, not legacy `token`.
- Include `groups` only when at least one group is present.
- Encode groups from validated entries sorted by `type`.
- Reject duplicate group types before encoding.
- Include `evaluation_contexts` only when at least one tag is present.
- Encode evaluation contexts sorted by raw value.
- Do not include person properties, group properties, GeoIP override headers, event data, analytics properties, or arbitrary JSON public values in v1.

## Response fields consumed by v1

V1 consumes:

```json
{
  "flags": {
    "my-awesome-flag": {
      "key": "my-awesome-flag",
      "enabled": true,
      "variant": "treatment"
    }
  },
  "errorsWhileComputingFlags": false,
  "quotaLimited": ["feature_flags"],
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

Rules:

- Unknown top-level fields are ignored.
- Unknown per-flag fields such as `reason`, `metadata`, and `metadata.payload` are ignored.
- `flags` missing or not an object is `invalidResponse`.
- Per-flag `enabled` missing or not a Boolean is `invalidResponse`.
- `requestId` is optional.
- `errorsWhileComputingFlags` defaults to `false` when absent.
- `quotaLimited` defaults to an empty set when absent.

## Variant decoding rules

Per-flag variant handling is conditional on `enabled`:

- When `enabled == true`, `variant` may be missing, `null`, or a string. Other shapes are `invalidResponse`.
- When `enabled == false`, any `variant` field is ignored regardless of shape.

Implementation note: decode per-flag objects with custom `Decodable` logic or equivalent internal parsing so invalid variant shapes can be ignored for disabled flags but rejected for enabled flags.

## Key consistency check

The dictionary key is the authoritative feature flag key.

If a per-flag `key` field is present and differs from the dictionary key, throw `invalidResponse`.

If the per-flag `key` field is absent, use the dictionary key.

## Mapping table

| PostHog fields | Graphit value |
| --- | --- |
| `enabled: false` | `FeatureFlag.disabled(key)` |
| `enabled: true`, no `variant` | `FeatureFlag.enabled(key)` |
| `enabled: true`, `variant: null` | `FeatureFlag.enabled(key)` |
| `enabled: true`, string `variant` | `FeatureFlag.variant(key, FeatureFlagVariant(variant))` |

Rules:

- A string variant implies enabled behavior only when `enabled == true`.
- If `enabled == false`, any variant field is ignored and maps to `.disabled`.
- `variant: null` is treated as no variant.
- Empty string variants are preserved and may be rejected by `GraphitFeatureFlags` validation.
- Holdout variants such as `holdout-727` are preserved as normal string variants.
- Sort PostHog flag entries by dictionary key before building `FeatureFlagSnapshot`.
- Build `FeatureFlags(snapshot:)` and throw `invalidFeatureFlagSnapshot` when core validation rejects mapped keys or variants.

## Evaluation metadata

`PostHogFeatureFlagEvaluation` maps:

- `featureFlags`: validated `FeatureFlags` built from mapped snapshot;
- `requestID`: PostHog `requestId` when present;
- `isPartial`: PostHog `errorsWhileComputingFlags`, defaulting to `false`;
- `quotaLimits`: `quotaLimited` values mapped to `PostHogQuotaLimit`, preserving unknown categories.

`isPartial == true` is not thrown. Quota limits are not thrown. Callers decide whether to use, cache, merge, or discard these results.

## Invalid response examples

Throw `invalidResponse` for:

- malformed JSON;
- missing `flags`;
- `flags` not an object;
- flag object missing Boolean `enabled`;
- enabled flag with non-string, non-null `variant`;
- per-flag `key` mismatch;
- non-array `quotaLimited` if present;
- non-Boolean `errorsWhileComputingFlags` if present;
- non-string `requestId` if present.

Do not expose raw response bodies in errors.
