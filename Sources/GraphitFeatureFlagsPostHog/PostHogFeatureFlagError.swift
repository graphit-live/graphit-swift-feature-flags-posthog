import GraphitFeatureFlags

/// Package-owned failure categories for PostHog feature-flag evaluation.
///
/// Cancellation is not represented by this error type and should propagate as
/// cancellation. Associated messages are intended to be sanitized by the SDK and
/// must not contain credentials, private identifiers, request bodies, or raw
/// response bodies.
public enum PostHogFeatureFlagError: Error, Sendable, Hashable, CustomStringConvertible {
    /// The client configuration cannot produce valid PostHog evaluation requests.
    case invalidConfiguration(String)

    /// The evaluation context supplied to `evaluateFeatureFlags(for:)` is malformed.
    case invalidInput(String)

    /// PostHog returned a non-success HTTP status code.
    case unexpectedStatusCode(Int)

    /// Transport failed after cancellation was preserved.
    case transportFailure(String)

    /// PostHog returned malformed JSON or an unsupported response shape.
    case invalidResponse(String)

    /// Mapped PostHog data was rejected by `GraphitFeatureFlags` validation.
    case invalidFeatureFlagSnapshot(FeatureFlagError)

    /// A human-readable sanitized description of the failure category.
    public var description: String {
        switch self {
        case .invalidConfiguration(let message):
            "Invalid PostHog feature flag configuration: \(message)"
        case .invalidInput(let message):
            "Invalid PostHog feature flag input: \(message)"
        case .unexpectedStatusCode(let statusCode):
            "Unexpected PostHog feature flag response status code: \(statusCode)"
        case .transportFailure(let message):
            "PostHog feature flag transport failure: \(message)"
        case .invalidResponse(let message):
            "Invalid PostHog feature flag response: \(message)"
        case .invalidFeatureFlagSnapshot:
            "Invalid feature flag snapshot returned by PostHog."
        }
    }
}
