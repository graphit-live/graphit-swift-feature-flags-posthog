/// Immutable configuration for a `PostHogFeatureFlagClient`.
///
/// The initializer stores values without validation and performs no I/O. Client
/// construction validates the project token, host, runtime policy, and request
/// timeout before the configuration can be used for evaluation requests.
public struct PostHogFeatureFlagConfiguration: Sendable {
    /// The PostHog project token used with the public `/flags` endpoint.
    public var projectToken: PostHogProjectToken

    /// The PostHog ingestion host used to build `/flags?v=2` requests.
    public var host: PostHogHost

    /// The semantic PostHog runtime signal used for runtime filtering.
    public var runtime: PostHogEvaluationRuntime

    /// The timeout applied to one PostHog feature-flag evaluation request.
    public var requestTimeout: Duration

    /// Creates a PostHog feature-flag configuration without validating it.
    ///
    /// - Parameters:
    ///   - projectToken: The PostHog project token for the public `/flags` endpoint.
    ///   - host: The PostHog ingestion host. Defaults to US Cloud.
    ///   - runtime: The runtime signal for PostHog filtering. Defaults to `.client`.
    ///   - requestTimeout: The timeout for one evaluation request. Defaults to 10 seconds.
    public init(
        projectToken: PostHogProjectToken,
        host: PostHogHost = .usCloud,
        runtime: PostHogEvaluationRuntime = .client,
        requestTimeout: Duration = .seconds(10)
    ) {
        self.projectToken = projectToken
        self.host = host
        self.runtime = runtime
        self.requestTimeout = requestTimeout
    }
}
