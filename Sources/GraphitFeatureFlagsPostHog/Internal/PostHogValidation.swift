import Foundation

internal struct ValidatedPostHogConfiguration: Sendable {
    internal let projectToken: PostHogProjectToken
    internal let host: PostHogHost
    internal let userAgent: String
    internal let requestTimeout: Duration
}

internal struct ValidatedPostHogFeatureFlagContext: Sendable {
    internal let distinctID: PostHogDistinctID
    internal let groups: [PostHogGroup]
    internal let evaluationContexts: [PostHogEvaluationContextTag]
}

internal enum PostHogValidation {
    internal static func validateConfiguration(
        _ configuration: PostHogFeatureFlagConfiguration
    ) throws -> ValidatedPostHogConfiguration {
        try validateProjectToken(configuration.projectToken)
        try validateHost(configuration.host)
        let userAgent = try validateRuntime(configuration.runtime)
        try validateRequestTimeout(configuration.requestTimeout)

        return ValidatedPostHogConfiguration(
            projectToken: configuration.projectToken,
            host: configuration.host,
            userAgent: userAgent,
            requestTimeout: configuration.requestTimeout
        )
    }

    internal static func validateContext(
        _ context: PostHogFeatureFlagContext
    ) throws -> ValidatedPostHogFeatureFlagContext {
        try validateDistinctID(context.distinctID)

        var seenGroupTypes: Set<String> = []
        var validatedGroups: [PostHogGroup] = []
        validatedGroups.reserveCapacity(context.groups.count)

        for group in context.groups {
            try validateGroup(group)

            guard seenGroupTypes.insert(group.type).inserted else {
                throw PostHogFeatureFlagError.invalidInput("Duplicate group types are not allowed.")
            }

            validatedGroups.append(group)
        }

        let sortedGroups = validatedGroups.sorted { lhs, rhs in
            lhs.type < rhs.type
        }

        var validatedEvaluationContexts: [PostHogEvaluationContextTag] = []
        validatedEvaluationContexts.reserveCapacity(context.evaluationContexts.count)

        for tag in context.evaluationContexts {
            try validateEvaluationContextTag(tag)
            validatedEvaluationContexts.append(tag)
        }

        let sortedEvaluationContexts = validatedEvaluationContexts.sorted { lhs, rhs in
            lhs.rawValue < rhs.rawValue
        }

        return ValidatedPostHogFeatureFlagContext(
            distinctID: context.distinctID,
            groups: sortedGroups,
            evaluationContexts: sortedEvaluationContexts
        )
    }

    internal static func containsControlScalar(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isControlScalar(scalar)
        }
    }

    private static func validateProjectToken(_ token: PostHogProjectToken) throws {
        if let message = invalidTextReason(
            token.rawValue,
            fieldName: "Project token",
            maximumLength: 512
        ) {
            throw PostHogFeatureFlagError.invalidConfiguration(message)
        }
    }

    private static func validateHost(_ host: PostHogHost) throws {
        guard let components = URLComponents(url: host.url, resolvingAgainstBaseURL: false) else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL is invalid.")
        }

        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL must use the http or https scheme.")
        }

        guard components.host?.isEmpty == false else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL must include a host.")
        }

        guard components.query == nil else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL must not include a query string.")
        }

        guard components.fragment == nil else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL must not include a fragment.")
        }

        guard components.user == nil, components.password == nil else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL must not include user information.")
        }

        guard components.path.isEmpty || components.path == "/" else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL must not include a non-root path.")
        }
    }

    private static func validateRuntime(_ runtime: PostHogEvaluationRuntime) throws -> String {
        let userAgent = runtime.userAgentForRequests

        if runtime.usesCustomUserAgent,
           let message = invalidTextReason(
               userAgent,
               fieldName: "Custom User-Agent",
               maximumLength: 512
           ) {
            throw PostHogFeatureFlagError.invalidConfiguration(message)
        }

        return userAgent
    }

    private static func validateRequestTimeout(_ requestTimeout: Duration) throws {
        guard requestTimeout > .zero else {
            throw PostHogFeatureFlagError.invalidConfiguration("Request timeout must be greater than zero.")
        }
    }

    private static func validateDistinctID(_ distinctID: PostHogDistinctID) throws {
        if let message = invalidTextReason(
            distinctID.rawValue,
            fieldName: "Distinct ID",
            maximumLength: 1_024
        ) {
            throw PostHogFeatureFlagError.invalidInput(message)
        }
    }

    private static func validateGroup(_ group: PostHogGroup) throws {
        if let message = invalidTextReason(
            group.type,
            fieldName: "Group type",
            maximumLength: 256
        ) {
            throw PostHogFeatureFlagError.invalidInput(message)
        }

        if let message = invalidTextReason(
            group.id,
            fieldName: "Group ID",
            maximumLength: 1_024
        ) {
            throw PostHogFeatureFlagError.invalidInput(message)
        }
    }

    private static func validateEvaluationContextTag(_ tag: PostHogEvaluationContextTag) throws {
        if let message = invalidTextReason(
            tag.rawValue,
            fieldName: "Evaluation context tag",
            maximumLength: 256
        ) {
            throw PostHogFeatureFlagError.invalidInput(message)
        }
    }

    private static func invalidTextReason(
        _ text: String,
        fieldName: String,
        maximumLength: Int
    ) -> String? {
        if text.isEmpty {
            return "\(fieldName) must not be empty."
        }

        if containsControlScalar(text) {
            return "\(fieldName) must not contain Unicode control characters."
        }

        if text.count > maximumLength {
            return "\(fieldName) must be no longer than \(maximumLength) characters."
        }

        return nil
    }

    private static func isControlScalar(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value <= 0x1F
            || scalar.value == 0x7F
            || (scalar.value >= 0x80 && scalar.value <= 0x9F)
    }
}
