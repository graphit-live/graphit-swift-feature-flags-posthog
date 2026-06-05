import Foundation
import GraphitFeatureFlags
@testable import GraphitFeatureFlagsPostHog
import Testing

@Suite("ResponseMapping")
struct ResponseMappingTests {
    @Test("disabled flags map to disabled FeatureFlags values")
    func disabledFlagMapping() throws {
        let evaluation = try evaluation(from: #"{"flags":{"disabled-flag":{"key":"disabled-flag","enabled":false}}}"#)

        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("disabled-flag")) == .disabled)
        #expect(evaluation.featureFlags.isEnabled(FeatureFlagKey("disabled-flag")) == false)
    }

    @Test("enabled flags with missing variant map to enabled values")
    func enabledMissingVariantMapping() throws {
        let evaluation = try evaluation(from: #"{"flags":{"enabled-flag":{"key":"enabled-flag","enabled":true}}}"#)

        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("enabled-flag")) == .enabled)
        #expect(evaluation.featureFlags.variant(for: FeatureFlagKey("enabled-flag")) == nil)
    }

    @Test("enabled flags with null variant map to enabled values")
    func enabledNullVariantMapping() throws {
        let evaluation = try evaluation(from: #"{"flags":{"enabled-flag":{"enabled":true,"variant":null}}}"#)

        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("enabled-flag")) == .enabled)
        #expect(evaluation.featureFlags.variant(for: FeatureFlagKey("enabled-flag")) == nil)
    }

    @Test("enabled flags with string variants map to variant values")
    func stringVariantMapping() throws {
        let evaluation = try evaluation(from: #"{"flags":{"experiment":{"enabled":true,"variant":"treatment"}}}"#)

        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("experiment")) == .variant(FeatureFlagVariant("treatment")))
        #expect(evaluation.featureFlags.variant(for: FeatureFlagKey("experiment")) == FeatureFlagVariant("treatment"))
    }

    @Test("holdout variants are preserved as normal string variants")
    func holdoutVariantPreservation() throws {
        let evaluation = try evaluation(from: #"{"flags":{"experiment":{"enabled":true,"variant":"holdout-727"}}}"#)

        #expect(evaluation.featureFlags.variant(for: FeatureFlagKey("experiment")) == FeatureFlagVariant("holdout-727"))
    }

    @Test("disabled flags ignore invalid variant shapes")
    func disabledFlagsIgnoreInvalidVariantShapes() throws {
        let evaluation = try evaluation(from: #"""
        {
          "flags": {
            "array-variant": {"enabled": false, "variant": ["not", "used"]},
            "bool-variant": {"enabled": false, "variant": true},
            "object-variant": {"enabled": false, "variant": {"not": "used"}}
          }
        }
        """#)

        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("array-variant")) == .disabled)
        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("bool-variant")) == .disabled)
        #expect(evaluation.featureFlags.value(for: FeatureFlagKey("object-variant")) == .disabled)
    }

    @Test("enabled flags reject invalid variant shapes")
    func enabledFlagsRejectInvalidVariantShapes() {
        let invalidVariants = ["true", "123", "[\"bad\"]", "{\"bad\":true}"]

        for invalidVariant in invalidVariants {
            let error = postHogError(from: """
            {
              "flags": {
                "enabled-flag": {"enabled": true, "variant": \(invalidVariant)}
              }
            }
            """)

            #expect(isInvalidResponse(error))
        }
    }

    @Test("unknown response metadata is ignored")
    func unknownMetadataIsIgnored() throws {
        let evaluation = try evaluation(from: #"""
        {
          "config": {"enable_collect_everything": true},
          "toolbarParams": {},
          "isAuthenticated": false,
          "supportedCompression": ["gzip"],
          "flags": {
            "metadata-flag": {
              "key": "metadata-flag",
              "enabled": true,
              "variant": "treatment",
              "reason": {
                "code": "condition_match",
                "description": "Condition matched"
              },
              "metadata": {
                "id": 1,
                "version": 2,
                "payload": "{\"example\":true}"
              }
            }
          }
        }
        """#)

        #expect(evaluation.featureFlags.variant(for: FeatureFlagKey("metadata-flag")) == FeatureFlagVariant("treatment"))
    }

    @Test("response flags are sorted by dictionary key before snapshot construction")
    func deterministicSnapshotOrdering() throws {
        let evaluation = try evaluation(from: #"""
        {
          "flags": {
            "z-flag": {"enabled": true},
            "a-flag": {"enabled": false},
            "m-flag": {"enabled": true, "variant": "middle"}
          }
        }
        """#)

        #expect(evaluation.featureFlags.snapshot.flags.map(\.key.rawValue) == ["a-flag", "m-flag", "z-flag"])
    }

    @Test("request ID partial and quota metadata are mapped")
    func responseMetadataMapping() throws {
        let evaluation = try evaluation(from: #"""
        {
          "flags": {},
          "errorsWhileComputingFlags": true,
          "quotaLimited": ["feature_flags", "unknown_category"],
          "requestId": "550e8400-e29b-41d4-a716-446655440000"
        }
        """#)

        #expect(evaluation.requestID == "550e8400-e29b-41d4-a716-446655440000")
        #expect(evaluation.isPartial)
        #expect(evaluation.quotaLimits == [.featureFlags, PostHogQuotaLimit("unknown_category")])
    }

    @Test("absent optional metadata defaults to non-partial empty quota metadata")
    func absentOptionalMetadataDefaults() throws {
        let evaluation = try evaluation(from: #"{"flags":{}}"#)

        #expect(evaluation.requestID == nil)
        #expect(evaluation.isPartial == false)
        #expect(evaluation.quotaLimits.isEmpty)
        #expect(evaluation.featureFlags.snapshot.flags.isEmpty)
    }

    @Test("missing or non-object flags are rejected")
    func invalidFlagsFieldRejection() {
        #expect(isInvalidResponse(postHogError(from: #"{}"#)))
        #expect(isInvalidResponse(postHogError(from: #"{"flags":[]}"#)))
        #expect(isInvalidResponse(postHogError(from: #"{"flags":null}"#)))
    }

    @Test("missing or non-Boolean enabled fields are rejected")
    func invalidEnabledFieldRejection() {
        #expect(isInvalidResponse(postHogError(from: #"{"flags":{"flag":{}}}"#)))
        #expect(isInvalidResponse(postHogError(from: #"{"flags":{"flag":{"enabled":"true"}}}"#)))
        #expect(isInvalidResponse(postHogError(from: #"{"flags":{"flag":{"enabled":null}}}"#)))
    }

    @Test("mismatched per-flag key is rejected")
    func mismatchedFlagKeyRejection() {
        let error = postHogError(from: #"{"flags":{"dictionary-key":{"key":"different-key","enabled":true}}}"#)

        #expect(isInvalidResponse(error))
    }

    @Test("malformed JSON is rejected without exposing the raw response body")
    func malformedJSONRejectionIsSanitized() {
        let rawResponseBody = "private_response_body"
        let error = postHogError(from: rawResponseBody)

        #expect(isInvalidResponse(error))
        #expect(error?.description.contains(rawResponseBody) == false)
    }

    @Test("invalid mapped snapshots wrap GraphitFeatureFlags validation errors")
    func invalidMappedSnapshotRejection() {
        let error = postHogError(from: #"{"flags":{"empty-variant":{"enabled":true,"variant":""}}}"#)

        guard case .invalidFeatureFlagSnapshot = error else {
            #expect(Bool(false))
            return
        }

        #expect(error?.description.contains("empty-variant") == false)
    }

    @Test("invalid metadata field shapes are rejected when present")
    func invalidMetadataFieldShapes() {
        #expect(isInvalidResponse(postHogError(from: #"{"flags":{},"errorsWhileComputingFlags":"false"}"#)))
        #expect(isInvalidResponse(postHogError(from: #"{"flags":{},"quotaLimited":"feature_flags"}"#)))
        #expect(isInvalidResponse(postHogError(from: #"{"flags":{},"requestId":123}"#)))
    }
}

private func evaluation(from json: String) throws -> PostHogFeatureFlagEvaluation {
    try PostHogFlagsMapper.makeEvaluation(from: Data(json.utf8))
}

private func postHogError(from json: String) -> PostHogFeatureFlagError? {
    do {
        _ = try evaluation(from: json)
        return nil
    } catch let error as PostHogFeatureFlagError {
        return error
    } catch {
        return nil
    }
}

private func isInvalidResponse(_ error: PostHogFeatureFlagError?) -> Bool {
    guard case .invalidResponse = error else {
        return false
    }

    return true
}
