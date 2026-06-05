import GraphitFeatureFlags

/// The SDK-produced result of one successful PostHog `/flags?v=2` evaluation.
///
/// The result contains a validated immutable `FeatureFlags` evaluator plus
/// PostHog metadata that helps callers reason about partial or quota-limited
/// results. This type has no public initializer in v1; apps should construct
/// `FeatureFlags` directly when they need local fixtures.
public struct PostHogFeatureFlagEvaluation: Sendable {
    /// The validated immutable feature-flag evaluator produced from PostHog results.
    public let featureFlags: FeatureFlags

    /// The PostHog request ID when the response includes one.
    public let requestID: String?

    /// Whether PostHog reported that some flags could not be computed.
    public let isPartial: Bool

    /// Quota-limit categories reported by PostHog.
    public let quotaLimits: Set<PostHogQuotaLimit>
}
