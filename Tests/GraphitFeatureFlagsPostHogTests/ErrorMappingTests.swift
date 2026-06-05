import Foundation
@testable import GraphitFeatureFlagsPostHog
import Testing

@Suite("ErrorMapping")
struct ErrorMappingTests {
    @Test("transport failures are sanitized")
    func transportFailureIsSanitized() async throws {
        let rawToken = "ph_private_token"
        let rawDistinctID = "private-user@example.com"
        let rawGroupID = "private-tenant"
        let rawUserAgent = "private-runtime/1.0"
        let rawRequestBodySnippet = #""api_key":"ph_private_token""#
        let lowLevelDetails = "network failed for \(rawToken) \(rawDistinctID) \(rawGroupID) \(rawUserAgent) \(rawRequestBodySnippet)"
        let fakeTransport = FakePostHogHTTPTransport(
            behavior: .failure(.failedWithSensitiveDetails(lowLevelDetails))
        )
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(projectToken: rawToken, runtime: .customUserAgent(rawUserAgent)),
            transport: fakeTransport
        )

        do {
            _ = try await client.evaluateFeatureFlags(
                for: context(
                    distinctID: rawDistinctID,
                    groups: [PostHogGroup(type: "company", id: rawGroupID)]
                )
            )
            #expect(Bool(false))
        } catch let error as PostHogFeatureFlagError {
            guard case .transportFailure = error else {
                #expect(Bool(false))
                return
            }

            assertNoSensitiveText(
                in: error.description,
                rawToken,
                rawDistinctID,
                rawGroupID,
                rawUserAgent,
                rawRequestBodySnippet,
                lowLevelDetails
            )
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("malformed successful responses throw sanitized invalidResponse")
    func malformedSuccessfulResponseThrowsInvalidResponse() async throws {
        let rawResponseBody = "private_response_body"
        let fakeTransport = FakePostHogHTTPTransport(
            behavior: .response(statusCode: 200, data: Data(rawResponseBody.utf8))
        )
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        do {
            _ = try await client.evaluateFeatureFlags(for: context())
            #expect(Bool(false))
        } catch let error as PostHogFeatureFlagError {
            guard case .invalidResponse = error else {
                #expect(Bool(false))
                return
            }

            #expect(!error.description.contains(rawResponseBody))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("invalid mapped snapshots throw invalidFeatureFlagSnapshot")
    func invalidMappedSnapshotThrows() async throws {
        let fakeTransport = FakePostHogHTTPTransport(
            behavior: .response(
                statusCode: 200,
                data: Data(#"{"flags":{"empty-variant":{"enabled":true,"variant":""}}}"#.utf8)
            )
        )
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        do {
            _ = try await client.evaluateFeatureFlags(for: context())
            #expect(Bool(false))
        } catch let error as PostHogFeatureFlagError {
            guard case .invalidFeatureFlagSnapshot = error else {
                #expect(Bool(false))
                return
            }

            #expect(!error.description.contains("empty-variant"))
            #expect(!error.description.contains("\"variant\":\"\""))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("unexpected status errors do not expose raw response bodies")
    func unexpectedStatusDoesNotExposeResponseBody() async throws {
        let rawResponseBody = "private_error_response_body"
        let fakeTransport = FakePostHogHTTPTransport(
            behavior: .response(statusCode: 401, data: Data(rawResponseBody.utf8))
        )
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        do {
            _ = try await client.evaluateFeatureFlags(for: context())
            #expect(Bool(false))
        } catch let error as PostHogFeatureFlagError {
            guard case .unexpectedStatusCode(401) = error else {
                #expect(Bool(false))
                return
            }

            #expect(!error.description.contains(rawResponseBody))
        } catch {
            #expect(Bool(false))
        }
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
    groups: [PostHogGroup] = []
) -> PostHogFeatureFlagContext {
    PostHogFeatureFlagContext(
        distinctID: PostHogDistinctID(distinctID),
        groups: groups
    )
}

private func assertNoSensitiveText(
    in description: String,
    _ sensitiveValues: String...
) {
    for sensitiveValue in sensitiveValues {
        #expect(!description.contains(sensitiveValue))
    }
}
