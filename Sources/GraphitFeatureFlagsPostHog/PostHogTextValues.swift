/// A PostHog project token used with the public `/flags` endpoint.
///
/// Construction stores the raw text without validation. `PostHogFeatureFlagClient`
/// validates the token before it can be used for requests. The textual
/// description is always redacted because project tokens must not be logged.
public struct PostHogProjectToken: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    /// The raw PostHog project token text.
    public let rawValue: String

    /// Creates a project token from raw text without validating it.
    ///
    /// - Parameter rawValue: The PostHog project token text.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a project token from raw text without validating it.
    ///
    /// - Parameter rawValue: The PostHog project token text.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A redacted description that never includes the raw project token.
    public var description: String {
        "<redacted PostHog project token>"
    }
}

/// A PostHog `distinct_id` for one feature-flag evaluation request.
///
/// Construction stores the raw text without validation. Evaluation validates
/// the ID before request construction. The textual description is always
/// redacted because distinct IDs may contain private user identifiers.
public struct PostHogDistinctID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    /// The raw PostHog distinct ID text.
    public let rawValue: String

    /// Creates a distinct ID from raw text without validating it.
    ///
    /// - Parameter rawValue: The PostHog distinct ID text.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a distinct ID from raw text without validating it.
    ///
    /// - Parameter rawValue: The PostHog distinct ID text.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A redacted description that never includes the raw distinct ID.
    public var description: String {
        "<redacted PostHog distinct ID>"
    }
}

/// One PostHog group used for group-based feature flags.
///
/// Construction stores the raw group type and ID without validation. Evaluation
/// validates groups and rejects duplicate group types before request
/// construction. The textual description is redacted because group IDs may
/// contain private account, organization, or tenant identifiers.
public struct PostHogGroup: Hashable, Sendable, CustomStringConvertible {
    /// The PostHog group type, such as an account or organization type.
    public let type: String

    /// The PostHog group identifier for `type`.
    public let id: String

    /// Creates a PostHog group without validating the supplied text.
    ///
    /// - Parameters:
    ///   - type: The group type.
    ///   - id: The group identifier.
    public init(type: String, id: String) {
        self.type = type
        self.id = id
    }

    /// A redacted description that never includes the raw group ID.
    public var description: String {
        "<redacted PostHog group>"
    }
}

/// A PostHog evaluation context tag used to filter evaluated flags.
///
/// Construction stores the raw tag text without validation. Evaluation validates
/// tags before request construction.
public struct PostHogEvaluationContextTag: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    /// The raw evaluation context tag text.
    public let rawValue: String

    /// Creates an evaluation context tag from raw text without validating it.
    ///
    /// - Parameter rawValue: The evaluation context tag text.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates an evaluation context tag from raw text without validating it.
    ///
    /// - Parameter rawValue: The evaluation context tag text.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The raw evaluation context tag text.
    public var description: String {
        rawValue
    }
}

/// One quota-limit category reported by PostHog's `/flags` response.
///
/// Unknown quota-limit categories are preserved as raw values.
public struct PostHogQuotaLimit: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    /// The PostHog quota category for feature-flag evaluation limits.
    public static let featureFlags: PostHogQuotaLimit = PostHogQuotaLimit("feature_flags")

    /// The raw PostHog quota-limit category.
    public let rawValue: String

    /// Creates a quota-limit category from raw PostHog response text.
    ///
    /// - Parameter rawValue: The raw quota-limit category.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a quota-limit category from raw PostHog response text.
    ///
    /// - Parameter rawValue: The raw quota-limit category.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The raw quota-limit category.
    public var description: String {
        rawValue
    }
}
