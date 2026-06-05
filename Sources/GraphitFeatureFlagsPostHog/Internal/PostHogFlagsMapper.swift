import Foundation
import GraphitFeatureFlags

internal enum PostHogFlagsMapper {
    internal static func makeEvaluation(from data: Data) throws -> PostHogFeatureFlagEvaluation {
        let response = try PostHogFlagsResponse.decode(from: data)

        return try makeEvaluation(from: response)
    }

    internal static func makeEvaluation(from response: PostHogFlagsResponse) throws -> PostHogFeatureFlagEvaluation {
        var mappedFlags: [FeatureFlag] = []
        mappedFlags.reserveCapacity(response.flags.count)

        for (dictionaryKey, flag) in response.flags.sorted(by: { lhs, rhs in lhs.key < rhs.key }) {
            if let responseKey = flag.key, responseKey != dictionaryKey {
                throw PostHogFeatureFlagError.invalidResponse(
                    "Flag key field does not match the response dictionary key."
                )
            }

            let key = FeatureFlagKey(dictionaryKey)

            if flag.enabled {
                if let variant = flag.variant {
                    mappedFlags.append(.variant(key, FeatureFlagVariant(variant)))
                } else {
                    mappedFlags.append(.enabled(key))
                }
            } else {
                mappedFlags.append(.disabled(key))
            }
        }

        let featureFlags: FeatureFlags
        do {
            featureFlags = try FeatureFlags(snapshot: FeatureFlagSnapshot(mappedFlags))
        } catch let error as FeatureFlagError {
            throw PostHogFeatureFlagError.invalidFeatureFlagSnapshot(error)
        } catch {
            throw PostHogFeatureFlagError.invalidFeatureFlagSnapshot(
                FeatureFlagError.invalidSnapshot("Feature flag snapshot validation failed.")
            )
        }

        return PostHogFeatureFlagEvaluation(
            featureFlags: featureFlags,
            requestID: response.requestID,
            isPartial: response.errorsWhileComputingFlags,
            quotaLimits: Set(response.quotaLimited.map { PostHogQuotaLimit($0) })
        )
    }
}
