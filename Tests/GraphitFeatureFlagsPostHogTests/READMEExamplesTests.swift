import Foundation
import GraphitFeatureFlags
import GraphitFeatureFlagsPostHog
import Testing

@Suite("READMEExamples")
struct READMEExamplesTests {
    @Test("quick start example compiles without performing network work")
    func quickStartExampleCompiles() throws {
        enum AppFlags {
            static let newHome = FeatureFlagKey("new-home")
        }

        let client = try PostHogFeatureFlagClient(configuration: .init(
            projectToken: PostHogProjectToken("ph_project_token"),
            host: .usCloud
        ))

        let context = PostHogFeatureFlagContext(
            distinctID: PostHogDistinctID("user-123")
        )

        let quickStart: @Sendable () async throws -> FeatureFlags = {
            let evaluation = try await client.evaluateFeatureFlags(for: context)
            let flags = evaluation.featureFlags

            if flags.isEnabled(AppFlags.newHome) {
                // Show the new home experience.
            }

            return flags
        }

        _ = quickStart
        #expect(client.configuration.projectToken == PostHogProjectToken("ph_project_token"))
    }

    @Test("explicit replacement update flow example compiles")
    func explicitReplacementUpdateFlowCompiles() throws {
        let refreshFeatureFlags: @Sendable (
            PostHogFeatureFlagClient,
            PostHogFeatureFlagContext
        ) async throws -> FeatureFlags = { client, context in
            var currentFlags = try FeatureFlags([])
            let refreshed = try await client.evaluateFeatureFlags(for: context)
            currentFlags = refreshed.featureFlags
            return currentFlags
        }

        _ = refreshFeatureFlags
        let initialFlags = try FeatureFlags([])
        #expect(initialFlags.snapshot.flags.isEmpty)
    }

    @Test("partial and quota metadata example compiles")
    func partialAndQuotaMetadataExampleCompiles() {
        let handleEvaluationMetadata: @Sendable (PostHogFeatureFlagEvaluation) -> (Bool, String?) = { evaluation in
            if evaluation.isPartial {
                // Decide whether to use, cache, merge, or discard this result.
            }

            let isQuotaLimited = evaluation.quotaLimits.contains(.featureFlags)
            let requestID = evaluation.requestID

            return (isQuotaLimited, requestID)
        }

        _ = handleEvaluationMetadata
    }

    @Test("app-owned FeatureFlagSnapshot caching example compiles")
    func appOwnedSnapshotCachingExampleCompiles() throws {
        let flags = try FeatureFlags([
            .enabled(FeatureFlagKey("new-home")),
            .variant(FeatureFlagKey("checkout-experiment"), FeatureFlagVariant("treatment"))
        ])

        let data = try JSONEncoder().encode(flags.snapshot)
        let cachedSnapshot = try JSONDecoder().decode(FeatureFlagSnapshot.self, from: data)
        let cachedFlags = try FeatureFlags(snapshot: cachedSnapshot)

        #expect(cachedFlags.isEnabled(FeatureFlagKey("new-home")))
        #expect(cachedFlags.variant(for: FeatureFlagKey("checkout-experiment")) == FeatureFlagVariant("treatment"))
    }
}
