# Task 03 — Response decoding and mapping

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/04_request_response_mapping.md`
- `implementation/02_public_api_contract.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/TESTING_QUALITY.md`

## Prereqs

- Task 02 done.
- `GraphitFeatureFlags` dependency builds.

## Implement

- Internal PostHog `/flags?v=2` response decoder.
- Internal mapper from decoded PostHog response to `PostHogFeatureFlagEvaluation`.
- Mapping into `FeatureFlagSnapshot` and then `FeatureFlags`.
- Internal initializer/factory for SDK-produced `PostHogFeatureFlagEvaluation` while keeping no public initializer.
- `PostHogQuotaLimit` mapping that preserves unknown categories.
- Sanitized `invalidResponse` messages.
- `invalidFeatureFlagSnapshot` wrapping when `GraphitFeatureFlags` rejects mapped data.

## Required decisions

- `flags` is required and must be an object.
- Per-flag `enabled` is required and must be Boolean.
- If per-flag `key` is present and differs from dictionary key, response is invalid.
- Unknown top-level and per-flag fields are ignored.
- Enabled flags accept missing, `null`, or string `variant`; other variant shapes are invalid.
- Disabled flags ignore any variant field regardless of shape.
- Empty string variant is preserved and may be rejected by core validation.
- Holdout variants are preserved as normal variants.
- Response flags are sorted by dictionary key before snapshot construction.
- `errorsWhileComputingFlags` defaults to `false`.
- `quotaLimited` defaults to an empty set.
- `isPartial` and `quotaLimits` are metadata, not thrown failures.

## Do not implement

- real URLSession execution;
- public raw PostHog response types;
- remote config/payload mapping;
- analytics/exposure behavior;
- cache behavior;
- typed payload decoding.

## Tests

Add Swift Testing coverage for:

- disabled, enabled, missing variant, null variant, string variant;
- holdout variant preservation;
- disabled flags ignoring invalid variant shapes;
- enabled flags rejecting invalid variant shapes;
- metadata/reason/payload ignored;
- deterministic sorted snapshot keys;
- request ID mapping;
- partial result mapping;
- quota limit mapping for `feature_flags` and unknown categories;
- absent optional metadata defaults;
- missing/non-object `flags` rejection;
- missing/non-Boolean `enabled` rejection;
- mismatched per-flag key rejection;
- malformed JSON rejection;
- invalid mapped snapshot rejection through `invalidFeatureFlagSnapshot`.

## Verify

```bash
swift build
swift test --filter ResponseMapping
```

## Definition of done

- PostHog response quirks are normalized internally.
- Public callers receive `FeatureFlags` and package-owned metadata only.
- No raw response body appears in public errors.
