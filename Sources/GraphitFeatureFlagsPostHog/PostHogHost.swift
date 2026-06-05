import Foundation

/// A PostHog ingestion base URL.
///
/// Construction stores the URL without validation. `PostHogFeatureFlagClient`
/// validates the URL shape before it can be used for evaluation requests.
public struct PostHogHost: Hashable, Sendable {
    /// The PostHog US Cloud ingestion host.
    public static let usCloud: PostHogHost = {
        guard let url = URL(string: "https://us.i.posthog.com") else {
            preconditionFailure("Invalid built-in PostHog US Cloud URL.")
        }

        return PostHogHost(url)
    }()

    /// The PostHog EU Cloud ingestion host.
    public static let euCloud: PostHogHost = {
        guard let url = URL(string: "https://eu.i.posthog.com") else {
            preconditionFailure("Invalid built-in PostHog EU Cloud URL.")
        }

        return PostHogHost(url)
    }()

    /// The raw PostHog ingestion base URL.
    public let url: URL

    /// Creates a PostHog host from a base URL without validating it.
    ///
    /// - Parameter url: The PostHog ingestion base URL.
    public init(_ url: URL) {
        self.url = url
    }
}
