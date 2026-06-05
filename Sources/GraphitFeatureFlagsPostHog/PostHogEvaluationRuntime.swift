/// The PostHog runtime signal used for `/flags` runtime filtering.
///
/// Use `.client` for the default client-runtime signal. Use
/// `customUserAgent(_:)` only when an integration intentionally needs to supply
/// a different PostHog runtime signal. Custom User-Agent text is redacted from
/// descriptions.
public struct PostHogEvaluationRuntime: Hashable, Sendable, CustomStringConvertible {
    private enum Storage: Hashable, Sendable {
        case client
        case customUserAgent(String)
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// The default client-runtime signal for PostHog feature-flag evaluation.
    public static let client: PostHogEvaluationRuntime = PostHogEvaluationRuntime(storage: .client)

    /// Creates a custom User-Agent runtime signal without validating it.
    ///
    /// `PostHogFeatureFlagClient` validates the custom text before it can be
    /// used for requests.
    ///
    /// - Parameter userAgent: The custom User-Agent text to send to PostHog.
    /// - Returns: A runtime value that stores the custom User-Agent text.
    public static func customUserAgent(_ userAgent: String) -> PostHogEvaluationRuntime {
        PostHogEvaluationRuntime(storage: .customUserAgent(userAgent))
    }

    /// A stable description of the runtime policy.
    ///
    /// Custom User-Agent text is never included in this description.
    public var description: String {
        switch storage {
        case .client:
            "PostHog client runtime"
        case .customUserAgent:
            "PostHog custom User-Agent runtime (redacted)"
        }
    }
}
