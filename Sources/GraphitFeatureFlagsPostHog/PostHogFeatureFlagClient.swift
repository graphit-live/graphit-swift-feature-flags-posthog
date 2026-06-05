import Foundation

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
    private let transport: any PostHogHTTPTransport

    /// Creates a PostHog feature-flag client.
    ///
    /// This initializer validates configuration and performs no network or
    /// filesystem I/O.
    ///
    /// - Parameter configuration: The PostHog feature-flag configuration.
    /// - Throws: `PostHogFeatureFlagError.invalidConfiguration` when validation rejects the configuration.
    public convenience init(configuration: PostHogFeatureFlagConfiguration) throws {
        try self.init(
            configuration: configuration,
            transport: URLSessionPostHogHTTPTransport()
        )
    }

    internal init(
        configuration: PostHogFeatureFlagConfiguration,
        transport: any PostHogHTTPTransport
    ) throws {
        self.validatedConfiguration = try PostHogValidation.validateConfiguration(configuration)
        self.configuration = configuration
        self.transport = transport
    }

    /// Evaluates PostHog feature flags for one context.
    ///
    /// Performs one cancellable HTTP `POST` to PostHog's `/flags?v=2` endpoint,
    /// maps the response into `FeatureFlags`, and returns request metadata for
    /// partial and quota-limited responses.
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

        let validatedContext = try PostHogValidation.validateContext(context)
        let request = try PostHogFlagsRequest.makeURLRequest(
            configuration: validatedConfiguration,
            context: validatedContext
        )

        try Task.checkCancellation()

        let response: PostHogHTTPTransportResponse
        do {
            response = try await transport.execute(request)
        } catch {
            if Self.isCancellation(error) {
                throw CancellationError()
            }

            throw Self.transportFailure(from: error)
        }

        try Task.checkCancellation()

        guard (200..<300).contains(response.statusCode) else {
            throw PostHogFeatureFlagError.unexpectedStatusCode(response.statusCode)
        }

        try Task.checkCancellation()

        return try PostHogFlagsMapper.makeEvaluation(from: response.data)
    }

    private static func isCancellation(_ error: any Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        return false
    }

    private static func transportFailure(from error: any Error) -> PostHogFeatureFlagError {
        if let urlError = error as? URLError, urlError.code == .timedOut {
            return .transportFailure("The PostHog feature flag request timed out.")
        }

        return .transportFailure("The PostHog feature flag request failed before a valid response was received.")
    }
}
