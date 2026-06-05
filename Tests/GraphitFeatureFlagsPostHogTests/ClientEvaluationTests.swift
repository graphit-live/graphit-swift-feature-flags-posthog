import Foundation
import GraphitFeatureFlags
@testable import GraphitFeatureFlagsPostHog
import Testing

@Suite("ClientEvaluation")
struct ClientEvaluationTests {
    @Test("initializer does not call transport")
    func initializerDoesNotCallTransport() async throws {
        let fakeTransport = FakePostHogHTTPTransport(behavior: .response(statusCode: 200, data: successResponseData()))

        _ = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        #expect(await fakeTransport.requestCount() == 0)
    }

    @Test("successful evaluation returns FeatureFlags and request metadata")
    func successfulEvaluation() async throws {
        let fakeTransport = FakePostHogHTTPTransport(behavior: .response(statusCode: 200, data: successResponseData()))
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        let evaluation = try await client.evaluateFeatureFlags(for: context())

        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("enabled-flag")) == .enabled)
        #expect(evaluation.featureFlags.variant(for: FeatureFlagKey("variant-flag")) == FeatureFlagVariant("treatment"))
        #expect(evaluation.requestID == "request-123")
        #expect(evaluation.isPartial == false)
        #expect(evaluation.quotaLimits.isEmpty)
    }

    @Test("one evaluation call records one transport request")
    func oneEvaluationRecordsOneTransportCall() async throws {
        let fakeTransport = FakePostHogHTTPTransport(behavior: .response(statusCode: 200, data: successResponseData()))
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        _ = try await client.evaluateFeatureFlags(for: context())

        #expect(await fakeTransport.requestCount() == 1)
        let requests = await fakeTransport.requests()
        let request = try #require(requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/flags")
    }

    @Test("invalid context throws before transport")
    func invalidContextThrowsBeforeTransport() async throws {
        let fakeTransport = FakePostHogHTTPTransport(behavior: .response(statusCode: 200, data: successResponseData()))
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        do {
            _ = try await client.evaluateFeatureFlags(for: context(distinctID: ""))
            #expect(Bool(false))
        } catch let error as PostHogFeatureFlagError {
            guard case .invalidInput = error else {
                #expect(Bool(false))
                return
            }
        } catch {
            #expect(Bool(false))
        }

        #expect(await fakeTransport.requestCount() == 0)
    }

    @Test("non-2xx responses throw unexpected status code")
    func nonSuccessStatusCodeThrows() async throws {
        let fakeTransport = FakePostHogHTTPTransport(
            behavior: .response(statusCode: 503, data: Data("private response body".utf8))
        )
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        do {
            _ = try await client.evaluateFeatureFlags(for: context())
            #expect(Bool(false))
        } catch let error as PostHogFeatureFlagError {
            guard case .unexpectedStatusCode(503) = error else {
                #expect(Bool(false))
                return
            }
        } catch {
            #expect(Bool(false))
        }

        #expect(await fakeTransport.requestCount() == 1)
    }
}

private func configuration(
    projectToken: String = "ph_project_token",
    runtime: PostHogEvaluationRuntime = .client
) -> PostHogFeatureFlagConfiguration {
    PostHogFeatureFlagConfiguration(
        projectToken: PostHogProjectToken(projectToken),
        runtime: runtime
    )
}

private func context(
    distinctID: String = "user-123",
    groups: [PostHogGroup] = [],
    evaluationContexts: Set<PostHogEvaluationContextTag> = []
) -> PostHogFeatureFlagContext {
    PostHogFeatureFlagContext(
        distinctID: PostHogDistinctID(distinctID),
        groups: groups,
        evaluationContexts: evaluationContexts
    )
}

private func successResponseData() -> Data {
    Data(#"{"flags":{"enabled-flag":{"enabled":true},"variant-flag":{"enabled":true,"variant":"treatment"}},"requestId":"request-123"}"#.utf8)
}
