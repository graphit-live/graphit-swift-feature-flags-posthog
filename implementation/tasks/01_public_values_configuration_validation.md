# Task 01 — Public values, configuration, validation, and redaction

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/02_public_api_contract.md`
- `implementation/03_validation_and_redaction.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/TESTING_QUALITY.md`

## Prereqs

- Task 00 done.

## Implement

Full behavior for public value/configuration types:

- `PostHogProjectToken` raw value and redacted description;
- `PostHogDistinctID` raw value and redacted description;
- `PostHogHost` built-ins and raw URL storage;
- `PostHogEvaluationRuntime.client`, `customUserAgent(_:)`, and redacted description;
- `PostHogGroup` stored type/id and redacted description;
- `PostHogEvaluationContextTag` raw value and description;
- `PostHogFeatureFlagContext` initializer defaults;
- `PostHogFeatureFlagConfiguration` initializer defaults;
- `PostHogQuotaLimit.featureFlags`, raw value, and description;
- `PostHogFeatureFlagError.description` sanitized category descriptions.

Add internal validation helpers for:

- project token;
- host URL;
- runtime User-Agent;
- request timeout;
- distinct ID;
- group type/ID and duplicate group types;
- evaluation context tags;
- control-scalar detection.

Make `PostHogFeatureFlagClient.init(configuration:)` validate configuration and create only inert/reusable internal state. It must not perform network or filesystem I/O.

## Required decisions

- Public text value construction is nonvalidating.
- Client initialization validates configuration.
- Evaluation validates context before request construction.
- Redacted descriptions do not include raw project token, distinct ID, group ID, or custom User-Agent text.
- `.client` runtime resolves internally to `posthog-ios/1.0.0 graphit-sdk/0.1.0`.
- `requestTimeout` must be greater than zero.

## Do not implement

- full request body construction beyond placeholders if needed;
- response decoding/mapping;
- real URLSession execution;
- public validation helpers;
- public transport/testing products;
- retry/cache/analytics/UI behavior.

## Tests

Add Swift Testing coverage for:

- raw-value construction does not validate;
- redacted descriptions;
- built-in hosts;
- custom host validation acceptance/rejection;
- project token validation;
- runtime and custom User-Agent validation;
- timeout validation;
- context validation for distinct ID, groups, duplicate group types, and evaluation context tags;
- initializer does not call transport or perform network work if a fake/no-op internal transport is available.

## Verify

```bash
swift build
swift test --filter ConfigurationValidation
swift test --filter ContextValidation
```

## Definition of done

- Public values/configuration behavior matches spec.
- Configuration validation happens in client initializer.
- Context validation can be used before networking.
- Raw sensitive values are redacted from descriptions/errors.
- Default `.client` User-Agent policy is internally available and tested.
