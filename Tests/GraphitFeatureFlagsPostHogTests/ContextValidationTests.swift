@testable import GraphitFeatureFlagsPostHog
import Testing

@Suite("ContextValidation")
struct ContextValidationTests {
    @Test("public context value construction stores raw input without validation")
    func rawContextConstructionDoesNotValidate() {
        let context = PostHogFeatureFlagContext(
            distinctID: PostHogDistinctID(""),
            groups: [PostHogGroup(type: "", id: "")],
            evaluationContexts: [PostHogEvaluationContextTag("")]
        )

        #expect(context.distinctID.rawValue == "")
        #expect(context.groups == [PostHogGroup(type: "", id: "")])
        #expect(context.evaluationContexts == [PostHogEvaluationContextTag("")])
    }

    @Test("valid distinct-ID-only context is accepted")
    func validDistinctIDOnlyContext() throws {
        let validated = try PostHogValidation.validateContext(
            PostHogFeatureFlagContext(distinctID: PostHogDistinctID("user-123"))
        )

        #expect(validated.distinctID == PostHogDistinctID("user-123"))
        #expect(validated.groups.isEmpty)
        #expect(validated.evaluationContexts.isEmpty)
    }

    @Test("valid optional groups are sorted deterministically")
    func groupsAreSorted() throws {
        let validated = try PostHogValidation.validateContext(
            PostHogFeatureFlagContext(
                distinctID: PostHogDistinctID("user-123"),
                groups: [
                    PostHogGroup(type: "z-company", id: "z-id"),
                    PostHogGroup(type: "a-company", id: "a-id")
                ]
            )
        )

        #expect(validated.groups.map(\.type) == ["a-company", "z-company"])
        #expect(validated.groups.map(\.id) == ["a-id", "z-id"])
    }

    @Test("valid evaluation context tags are sorted deterministically")
    func evaluationContextsAreSorted() throws {
        let validated = try PostHogValidation.validateContext(
            PostHogFeatureFlagContext(
                distinctID: PostHogDistinctID("user-123"),
                evaluationContexts: [
                    PostHogEvaluationContextTag("production"),
                    PostHogEvaluationContextTag("ios")
                ]
            )
        )

        #expect(validated.evaluationContexts.map(\.rawValue) == ["ios", "production"])
    }

    @Test("distinct ID validation rejects malformed text")
    func distinctIDValidation() {
        #expect(invalidInputDescription(for: context(distinctID: "")) != nil)
        #expect(invalidInputDescription(for: context(distinctID: "private-user\n")) != nil)
        #expect(invalidInputDescription(for: context(distinctID: "private-user\u{85}")) != nil)
        #expect(invalidInputDescription(for: context(distinctID: String(repeating: "a", count: 1_025))) != nil)
    }

    @Test("group validation rejects malformed and duplicate groups")
    func groupValidation() {
        #expect(
            invalidInputDescription(
                for: context(groups: [PostHogGroup(type: "", id: "tenant-1")])
            ) != nil
        )
        #expect(
            invalidInputDescription(
                for: context(groups: [PostHogGroup(type: "company\n", id: "tenant-1")])
            ) != nil
        )
        #expect(
            invalidInputDescription(
                for: context(groups: [PostHogGroup(type: String(repeating: "a", count: 257), id: "tenant-1")])
            ) != nil
        )
        #expect(
            invalidInputDescription(
                for: context(groups: [PostHogGroup(type: "company", id: "")])
            ) != nil
        )

        let privateGroupID = "private-tenant\n"
        let groupIDDescription = invalidInputDescription(
            for: context(groups: [PostHogGroup(type: "company", id: privateGroupID)])
        )
        #expect(groupIDDescription != nil)
        #expect(groupIDDescription?.contains(privateGroupID) == false)
        #expect(groupIDDescription?.contains("private-tenant") == false)

        #expect(
            invalidInputDescription(
                for: context(groups: [
                    PostHogGroup(type: "company", id: "tenant-1"),
                    PostHogGroup(type: "company", id: "tenant-2")
                ])
            ) != nil
        )
    }

    @Test("evaluation context tag validation rejects malformed text")
    func evaluationContextTagValidation() {
        #expect(
            invalidInputDescription(
                for: context(evaluationContexts: [PostHogEvaluationContextTag("")])
            ) != nil
        )
        #expect(
            invalidInputDescription(
                for: context(evaluationContexts: [PostHogEvaluationContextTag("production\n")])
            ) != nil
        )
        #expect(
            invalidInputDescription(
                for: context(evaluationContexts: [PostHogEvaluationContextTag(String(repeating: "a", count: 257))])
            ) != nil
        )
    }

    @Test("client evaluation rejects invalid context before transport work")
    func clientEvaluationRejectsInvalidContext() async throws {
        let privateDistinctID = "private-user\n"
        let client = try PostHogFeatureFlagClient(
            configuration: PostHogFeatureFlagConfiguration(
                projectToken: PostHogProjectToken("ph_project_token")
            )
        )

        do {
            _ = try await client.evaluateFeatureFlags(for: context(distinctID: privateDistinctID))
            #expect(Bool(false))
        } catch let error as PostHogFeatureFlagError {
            guard case .invalidInput = error else {
                #expect(Bool(false))
                return
            }

            #expect(!error.description.contains(privateDistinctID))
            #expect(!error.description.contains("private-user"))
        } catch {
            #expect(Bool(false))
        }
    }
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

private func invalidInputDescription(for context: PostHogFeatureFlagContext) -> String? {
    do {
        _ = try PostHogValidation.validateContext(context)
        return nil
    } catch let error as PostHogFeatureFlagError {
        guard case .invalidInput = error else {
            return nil
        }

        return error.description
    } catch {
        return nil
    }
}
