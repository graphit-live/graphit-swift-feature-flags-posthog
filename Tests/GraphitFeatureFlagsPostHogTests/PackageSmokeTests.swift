import Foundation
import GraphitFeatureFlagsPostHog
import Testing

@Suite("Package smoke tests")
struct PackageSmokeTests {
    @Test("public API shell constructs a client without I/O")
    func clientShellConstructs() throws {
        let configuration = PostHogFeatureFlagConfiguration(
            projectToken: PostHogProjectToken("ph_project_token")
        )

        let client = try PostHogFeatureFlagClient(configuration: configuration)

        #expect(client.configuration.projectToken == configuration.projectToken)
        #expect(PostHogHost.usCloud.url == URL(string: "https://us.i.posthog.com"))
        #expect(PostHogHost.euCloud.url == URL(string: "https://eu.i.posthog.com"))
    }
}
