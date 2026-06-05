/// Caller-provided inputs for one PostHog `/flags?v=2` evaluation request.
///
/// The initializer stores values without validation and performs no I/O.
/// `PostHogFeatureFlagClient.evaluateFeatureFlags(for:)` validates the context
/// before request construction and networking.
public struct PostHogFeatureFlagContext: Hashable, Sendable {
    /// The PostHog distinct ID for the evaluation request.
    public var distinctID: PostHogDistinctID

    /// Optional PostHog groups for group-based feature flags.
    public var groups: [PostHogGroup]

    /// Optional set-like evaluation context tags for PostHog filtering.
    public var evaluationContexts: Set<PostHogEvaluationContextTag>

    /// Creates an evaluation context without validating it.
    ///
    /// - Parameters:
    ///   - distinctID: The PostHog distinct ID for this request.
    ///   - groups: Optional groups for group-based feature flags.
    ///   - evaluationContexts: Optional evaluation context tags for filtering.
    public init(
        distinctID: PostHogDistinctID,
        groups: [PostHogGroup] = [],
        evaluationContexts: Set<PostHogEvaluationContextTag> = []
    ) {
        self.distinctID = distinctID
        self.groups = groups
        self.evaluationContexts = evaluationContexts
    }
}
