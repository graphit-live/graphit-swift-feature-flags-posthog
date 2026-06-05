import Foundation
@testable import GraphitFeatureFlagsPostHog
import Testing

@Suite("RequestConstruction")
struct RequestConstructionTests {
    @Test("request uses POST flags endpoint query and required headers")
    func methodEndpointQueryAndHeaders() throws {
        let request = try makeRequest()
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(request.httpMethod == "POST")
        #expect(components.scheme == "https")
        #expect(components.host == "us.i.posthog.com")
        #expect(components.path == "/flags")
        #expect(components.queryItems?.count == 1)
        #expect(components.queryItems?.first?.name == "v")
        #expect(components.queryItems?.first?.value == "2")
        #expect(components.queryItems?.contains { $0.name == "config" } == false)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "posthog-ios/1.0.0 graphit-sdk/0.1.0")
    }

    @Test("default User-Agent is locked for v0.1.0 client runtime")
    func defaultUserAgent() throws {
        let request = try makeRequest()
        let userAgent = try #require(request.value(forHTTPHeaderField: "User-Agent"))

        #expect(userAgent == "posthog-ios/1.0.0 graphit-sdk/0.1.0")
        #expect(userAgent.hasPrefix("posthog-ios/1.0.0"))
    }

    @Test("custom User-Agent is sent exactly")
    func customUserAgent() throws {
        let customUserAgent = "custom-runtime/2.0 graphit-test/1.0"
        let request = try makeRequest(runtime: .customUserAgent(customUserAgent))

        #expect(request.value(forHTTPHeaderField: "User-Agent") == customUserAgent)
    }

    @Test("request timeout is applied to the URLRequest")
    func requestTimeout() throws {
        let request = try makeRequest(requestTimeout: .seconds(7))

        #expect(request.timeoutInterval == 7)
    }

    @Test("body uses api key and distinct ID without legacy token")
    func bodyUsesAPIKeyAndDistinctID() throws {
        let request = try makeRequest(
            projectToken: "ph_project_token",
            distinctID: "user-123"
        )
        let body = try decodedBody(from: request)

        #expect(body.apiKey == "ph_project_token")
        #expect(body.distinctID == "user-123")
        #expect(body.token == nil)
    }

    @Test("empty optional groups and evaluation contexts are omitted")
    func emptyOptionalFieldsAreOmitted() throws {
        let request = try makeRequest()
        let body = try decodedBody(from: request)
        let bodyText = try bodyText(from: request)

        #expect(body.groups == nil)
        #expect(body.evaluationContexts == nil)
        #expect(!bodyText.contains("groups"))
        #expect(!bodyText.contains("evaluation_contexts"))
    }

    @Test("groups are encoded from validated sorted group types")
    func sortedGroups() throws {
        let request = try makeRequest(
            groups: [
                PostHogGroup(type: "z-company", id: "z-id"),
                PostHogGroup(type: "a-company", id: "a-id"),
                PostHogGroup(type: "m-company", id: "m-id")
            ]
        )
        let body = try decodedBody(from: request)
        let bodyText = try bodyText(from: request)

        #expect(body.groups == [
            "a-company": "a-id",
            "m-company": "m-id",
            "z-company": "z-id"
        ])

        let aIndex = try firstIndex(of: "\"a-company\"", in: bodyText)
        let mIndex = try firstIndex(of: "\"m-company\"", in: bodyText)
        let zIndex = try firstIndex(of: "\"z-company\"", in: bodyText)
        #expect(aIndex < mIndex)
        #expect(mIndex < zIndex)
    }

    @Test("evaluation contexts are encoded sorted by raw value")
    func sortedEvaluationContexts() throws {
        let request = try makeRequest(
            evaluationContexts: [
                PostHogEvaluationContextTag("production"),
                PostHogEvaluationContextTag("ios"),
                PostHogEvaluationContextTag("beta")
            ]
        )
        let body = try decodedBody(from: request)

        #expect(body.evaluationContexts == ["beta", "ios", "production"])
    }

    @Test("request body excludes deferred v1 fields")
    func deferredFieldsAreNotEncoded() throws {
        let request = try makeRequest(
            groups: [PostHogGroup(type: "company", id: "graphit")],
            evaluationContexts: [PostHogEvaluationContextTag("ios")]
        )
        let bodyText = try bodyText(from: request)

        #expect(!bodyText.contains("\"token\""))
        #expect(!bodyText.contains("\"config\""))
        #expect(!bodyText.contains("\"person_properties\""))
        #expect(!bodyText.contains("\"group_properties\""))
        #expect(!bodyText.contains("\"evaluation_environments\""))
        #expect(!bodyText.contains("\"event\""))
        #expect(!bodyText.contains("\"properties\""))
    }

    @Test("one evaluation context produces one complete request shape")
    func oneContextProducesOneRequestShape() throws {
        let request = try makeRequest(
            host: PostHogHost(URL(string: "http://localhost:8000")!),
            groups: [PostHogGroup(type: "company", id: "graphit")],
            evaluationContexts: [PostHogEvaluationContextTag("local")]
        )
        let url = try #require(request.url)
        let body = try decodedBody(from: request)

        #expect(url.absoluteString == "http://localhost:8000/flags?v=2")
        #expect(request.httpMethod == "POST")
        #expect(body.groups == ["company": "graphit"])
        #expect(body.evaluationContexts == ["local"])
    }
}

private struct DecodedRequestBody: Decodable {
    let apiKey: String?
    let distinctID: String?
    let token: String?
    let groups: [String: String]?
    let evaluationContexts: [String]?

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case distinctID = "distinct_id"
        case token
        case groups
        case evaluationContexts = "evaluation_contexts"
    }
}

private func makeRequest(
    projectToken: String = "ph_project_token",
    host: PostHogHost = .usCloud,
    runtime: PostHogEvaluationRuntime = .client,
    requestTimeout: Duration = .seconds(10),
    distinctID: String = "user-123",
    groups: [PostHogGroup] = [],
    evaluationContexts: Set<PostHogEvaluationContextTag> = []
) throws -> URLRequest {
    let configuration = PostHogFeatureFlagConfiguration(
        projectToken: PostHogProjectToken(projectToken),
        host: host,
        runtime: runtime,
        requestTimeout: requestTimeout
    )
    let context = PostHogFeatureFlagContext(
        distinctID: PostHogDistinctID(distinctID),
        groups: groups,
        evaluationContexts: evaluationContexts
    )

    return try PostHogFlagsRequest.makeURLRequest(
        configuration: PostHogValidation.validateConfiguration(configuration),
        context: PostHogValidation.validateContext(context)
    )
}

private func decodedBody(from request: URLRequest) throws -> DecodedRequestBody {
    let body = try #require(request.httpBody)

    return try JSONDecoder().decode(DecodedRequestBody.self, from: body)
}

private func bodyText(from request: URLRequest) throws -> String {
    let body = try #require(request.httpBody)

    return try #require(String(data: body, encoding: .utf8))
}

private func firstIndex(of needle: String, in text: String) throws -> String.Index {
    try #require(text.range(of: needle)?.lowerBound)
}
