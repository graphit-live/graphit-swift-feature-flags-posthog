# Task index

Each task is independently assignable after prerequisites. Required in every task: read `implementation/README.md`, `implementation/00_decisions.md`, relevant design docs, task file, `Spec.md`, and companion guides. If implementation shifts from task/spec, stop and align before continuing.

Minimal v1 scope: explicit PostHog `/flags?v=2` evaluation adapter. No provider protocols, no caching, no persistence, no GraphitCache dependency, no analytics/exposure tracking, no UI adapters, no globals, no refresh loops, no generated clients, no vendor SDK imports, no public transport/testing products.

## Vertical order

0. Bootstrap package and API shell.
1. Public values, configuration, validation, and redaction.
2. Request construction.
3. Response decoding and mapping.
4. Client evaluation, transport, errors, and cancellation.
5. Public docs and README audit.
6. Test hardening and release check.

Why this order: every slice proves user-visible behavior before adding deeper internals. The implementation should remain a small concrete adapter over `GraphitFeatureFlags`.
