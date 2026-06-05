import Foundation
@testable import GraphitFeatureFlagsPostHog
import Testing

@Suite("ConfigurationValidation")
struct ConfigurationValidationTests {
    @Test("public value construction stores raw configuration text without validation")
    func rawValueConstructionDoesNotValidate() {
        let token = PostHogProjectToken("")
        let hostURL = URL(string: "ftp://user:password@example.com/not-root?secret=value#fragment")!
        let host = PostHogHost(hostURL)
        let runtime = PostHogEvaluationRuntime.customUserAgent("")
        let configuration = PostHogFeatureFlagConfiguration(
            projectToken: token,
            host: host,
            runtime: runtime,
            requestTimeout: .zero
        )

        #expect(token.rawValue == "")
        #expect(host.url == hostURL)
        #expect(runtime.userAgentForRequests == "")
        #expect(configuration.projectToken == token)
        #expect(configuration.host == host)
        #expect(configuration.runtime == runtime)
        #expect(configuration.requestTimeout == .zero)
    }

    @Test("sensitive descriptions are redacted")
    func sensitiveDescriptionsAreRedacted() {
        let rawToken = "ph_secret_project_token"
        let rawDistinctID = "private-user@example.com"
        let rawGroupID = "tenant-secret"
        let rawUserAgent = "private-runtime/1.0"

        #expect(!PostHogProjectToken(rawToken).description.contains(rawToken))
        #expect(!PostHogDistinctID(rawDistinctID).description.contains(rawDistinctID))
        #expect(!PostHogGroup(type: "company", id: rawGroupID).description.contains(rawGroupID))
        #expect(!PostHogEvaluationRuntime.customUserAgent(rawUserAgent).description.contains(rawUserAgent))
        #expect(PostHogEvaluationContextTag("production").description == "production")
        #expect(PostHogQuotaLimit.featureFlags.rawValue == "feature_flags")
        #expect(PostHogQuotaLimit.featureFlags.description == "feature_flags")
        #expect(PostHogQuotaLimit("unknown_category").description == "unknown_category")
    }

    @Test("built-in hosts match PostHog ingestion hosts")
    func builtInHosts() {
        #expect(PostHogHost.usCloud.url == URL(string: "https://us.i.posthog.com"))
        #expect(PostHogHost.euCloud.url == URL(string: "https://eu.i.posthog.com"))
    }

    @Test("configuration initializer applies v1 defaults")
    func configurationDefaults() {
        let configuration = PostHogFeatureFlagConfiguration(
            projectToken: PostHogProjectToken("ph_project_token")
        )

        #expect(configuration.host == .usCloud)
        #expect(configuration.runtime == .client)
        #expect(configuration.requestTimeout == .seconds(10))
    }

    @Test("valid configurations are accepted")
    func validConfigurationsAreAccepted() {
        #expect(isValidConfiguration(configuration()))
        #expect(isValidConfiguration(configuration(host: .euCloud)))
        #expect(isValidConfiguration(configuration(host: PostHogHost(URL(string: "http://localhost:8000")!))))
        #expect(isValidConfiguration(configuration(host: PostHogHost(URL(string: "https://posthog.example.com/")!))))
        #expect(isValidConfiguration(configuration(runtime: .customUserAgent("posthog-ios/custom graphit-test/1.0"))))
        #expect(isValidConfiguration(configuration(projectToken: String(repeating: "a", count: 512))))
    }

    @Test("invalid custom hosts are rejected")
    func invalidHostsAreRejected() {
        let invalidHosts = [
            URL(string: "//example.com")!,
            URL(string: "ftp://example.com")!,
            URL(string: "https:/")!,
            URL(string: "https://example.com?query=value")!,
            URL(string: "https://example.com#fragment")!,
            URL(string: "https://user:password@example.com")!,
            URL(string: "https://example.com/not-root")!
        ]

        for url in invalidHosts {
            #expect(invalidConfigurationDescription(for: configuration(host: PostHogHost(url))) != nil)
        }
    }

    @Test("project token validation rejects malformed text")
    func projectTokenValidation() {
        #expect(invalidConfigurationDescription(for: configuration(projectToken: "")) != nil)
        #expect(invalidConfigurationDescription(for: configuration(projectToken: "ph_\nsecret")) != nil)
        #expect(invalidConfigurationDescription(for: configuration(projectToken: "ph_\u{7F}secret")) != nil)
        #expect(invalidConfigurationDescription(for: configuration(projectToken: String(repeating: "a", count: 513))) != nil)
    }

    @Test("runtime User-Agent policy is validated and internally resolvable")
    func runtimeValidation() {
        let defaultUserAgent = "posthog-ios/1.0.0 graphit-sdk/0.1.0"
        #expect(PostHogEvaluationRuntime.defaultClientUserAgent == defaultUserAgent)
        #expect(PostHogEvaluationRuntime.client.userAgentForRequests == defaultUserAgent)
        #expect(PostHogEvaluationRuntime.client.userAgentForRequests.hasPrefix("posthog-ios/1.0.0"))

        let customUserAgent = "custom-runtime/2.0 graphit-test/1.0"
        let customRuntime = PostHogEvaluationRuntime.customUserAgent(customUserAgent)
        #expect(customRuntime.userAgentForRequests == customUserAgent)
        #expect(isValidConfiguration(configuration(runtime: customRuntime)))

        #expect(invalidConfigurationDescription(for: configuration(runtime: .customUserAgent(""))) != nil)

        let privateUserAgent = "private-runtime\nsecret"
        let controlDescription = invalidConfigurationDescription(
            for: configuration(runtime: .customUserAgent(privateUserAgent))
        )
        #expect(controlDescription != nil)
        #expect(controlDescription?.contains(privateUserAgent) == false)
        #expect(controlDescription?.contains("private-runtime") == false)

        #expect(
            invalidConfigurationDescription(
                for: configuration(runtime: .customUserAgent(String(repeating: "a", count: 513)))
            ) != nil
        )
    }

    @Test("request timeout must be positive")
    func requestTimeoutValidation() {
        #expect(isValidConfiguration(configuration(requestTimeout: .seconds(1))))
        #expect(invalidConfigurationDescription(for: configuration(requestTimeout: .zero)) != nil)
        #expect(invalidConfigurationDescription(for: configuration(requestTimeout: .seconds(-1))) != nil)
    }

    @Test("configuration error descriptions are sanitized")
    func configurationErrorsAreSanitized() {
        let rawToken = "ph_private_token\n"
        let tokenDescription = invalidConfigurationDescription(for: configuration(projectToken: rawToken))
        #expect(tokenDescription != nil)
        #expect(tokenDescription?.contains(rawToken) == false)
        #expect(tokenDescription?.contains("ph_private_token") == false)

        let rawUserAgent = "secret-runtime\n1.0"
        let runtimeDescription = invalidConfigurationDescription(
            for: configuration(runtime: .customUserAgent(rawUserAgent))
        )
        #expect(runtimeDescription != nil)
        #expect(runtimeDescription?.contains(rawUserAgent) == false)
        #expect(runtimeDescription?.contains("secret-runtime") == false)
    }
}

private func configuration(
    projectToken: String = "ph_project_token",
    host: PostHogHost = .usCloud,
    runtime: PostHogEvaluationRuntime = .client,
    requestTimeout: Duration = .seconds(10)
) -> PostHogFeatureFlagConfiguration {
    PostHogFeatureFlagConfiguration(
        projectToken: PostHogProjectToken(projectToken),
        host: host,
        runtime: runtime,
        requestTimeout: requestTimeout
    )
}

private func isValidConfiguration(_ configuration: PostHogFeatureFlagConfiguration) -> Bool {
    (try? PostHogFeatureFlagClient(configuration: configuration)) != nil
}

private func invalidConfigurationDescription(
    for configuration: PostHogFeatureFlagConfiguration
) -> String? {
    do {
        _ = try PostHogFeatureFlagClient(configuration: configuration)
        return nil
    } catch let error as PostHogFeatureFlagError {
        guard case .invalidConfiguration = error else {
            return nil
        }

        return error.description
    } catch {
        return nil
    }
}
