import Foundation

internal enum PostHogFlagsRequest {
    internal static func makeURLRequest(
        configuration: ValidatedPostHogConfiguration,
        context: ValidatedPostHogFeatureFlagContext
    ) throws -> URLRequest {
        let url = try flagsEndpointURL(for: configuration.host)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.requestTimeout.urlRequestTimeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try requestBodyData(configuration: configuration, context: context)

        return request
    }

    private static func flagsEndpointURL(for host: PostHogHost) throws -> URL {
        guard var components = URLComponents(url: host.url, resolvingAgainstBaseURL: false) else {
            throw PostHogFeatureFlagError.invalidConfiguration("Host URL could not be used to build the flags endpoint.")
        }

        components.path = "/flags"
        components.queryItems = [URLQueryItem(name: "v", value: "2")]

        guard let url = components.url else {
            throw PostHogFeatureFlagError.invalidConfiguration("Flags endpoint URL could not be constructed.")
        }

        return url
    }

    private static func requestBodyData(
        configuration: ValidatedPostHogConfiguration,
        context: ValidatedPostHogFeatureFlagContext
    ) throws -> Data {
        let groups: [String: String]? = if context.groups.isEmpty {
            nil
        } else {
            Dictionary(uniqueKeysWithValues: context.groups.map { group in
                (group.type, group.id)
            })
        }

        let evaluationContexts: [String]? = if context.evaluationContexts.isEmpty {
            nil
        } else {
            context.evaluationContexts.map(\.rawValue)
        }

        let body = RequestBody(
            apiKey: configuration.projectToken.rawValue,
            distinctID: context.distinctID.rawValue,
            groups: groups,
            evaluationContexts: evaluationContexts
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        do {
            return try encoder.encode(body)
        } catch {
            throw PostHogFeatureFlagError.invalidInput("PostHog feature flag request body could not be encoded.")
        }
    }
}

private struct RequestBody: Encodable {
    let apiKey: String
    let distinctID: String
    let groups: [String: String]?
    let evaluationContexts: [String]?

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case distinctID = "distinct_id"
        case groups
        case evaluationContexts = "evaluation_contexts"
    }
}

private extension Duration {
    var urlRequestTimeoutInterval: TimeInterval {
        let durationComponents = components
        let seconds = Double(durationComponents.seconds)
        let attoseconds = Double(durationComponents.attoseconds) / 1_000_000_000_000_000_000

        return seconds + attoseconds
    }
}
