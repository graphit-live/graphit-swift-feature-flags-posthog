/// A resource-owning PostHog feature-flag evaluation client.
///
/// The client stores immutable configuration and is safe to pass across
/// concurrency domains. It is not `MainActor`-isolated. Initializing the client
/// performs configuration setup only and must not contact PostHog, touch the
/// filesystem, start background work, or read app state.
public final class PostHogFeatureFlagClient: Sendable {
    /// The configuration supplied when the client was created.
    public let configuration: PostHogFeatureFlagConfiguration

    private let validatedConfiguration: ValidatedPostHogConfiguration

    /// Creates a PostHog feature-flag client.
    ///
    /// This initializer validates configuration and performs no network or
    /// filesystem I/O.
    ///
    /// - Parameter configuration: The PostHog feature-flag configuration.
    /// - Throws: `PostHogFeatureFlagError.invalidConfiguration` when validation rejects the configuration.
    public init(configuration: PostHogFeatureFlagConfiguration) throws {
        self.validatedConfiguration = try PostHogValidation.validateConfiguration(configuration)
        self.configuration = configuration
    }

    /// Evaluates PostHog feature flags for one context.
    ///
    /// The complete v1 implementation performs one cancellable HTTP `POST` to
    /// PostHog's `/flags?v=2` endpoint, maps the response into `FeatureFlags`,
    /// and returns request metadata for partial and quota-limited responses.
    /// The package shell does not perform network work.
    ///
    /// - Parameter context: The PostHog evaluation context for one request.
    /// - Returns: A validated feature-flag evaluation result.
    /// - Throws: `PostHogFeatureFlagError` for package-owned configuration,
    ///   input, transport, response, or mapping failures. Cancellation is
    ///   preserved and is not wrapped in this error type.
    public func evaluateFeatureFlags(
        for context: PostHogFeatureFlagContext
    ) async throws -> PostHogFeatureFlagEvaluation {
        try Task.checkCancellation()
        _ = try PostHogValidation.validateContext(context)

        throw PostHogFeatureFlagError.transportFailure(
            "PostHog feature flag evaluation is not implemented in this package shell."
        )
    }
}
