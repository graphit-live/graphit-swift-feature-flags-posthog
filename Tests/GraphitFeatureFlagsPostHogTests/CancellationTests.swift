import Foundation
@testable import GraphitFeatureFlagsPostHog
import Testing

@Suite("Cancellation")
struct CancellationTests {
    @Test("cancellation before request avoids transport")
    func cancellationBeforeRequestAvoidsTransport() async throws {
        let fakeTransport = FakePostHogHTTPTransport(behavior: .response(statusCode: 200, data: successResponseData()))
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )
        let gate = AsyncGate()

        let task = Task {
            await gate.wait()
            return try await client.evaluateFeatureFlags(for: context())
        }

        task.cancel()
        await gate.open()

        do {
            _ = try await task.value
            #expect(Bool(false))
        } catch is CancellationError {
            // Expected.
        } catch {
            #expect(Bool(false))
        }

        #expect(await fakeTransport.requestCount() == 0)
    }

    @Test("transport cancellation is preserved")
    func transportCancellationIsPreserved() async throws {
        let fakeTransport = FakePostHogHTTPTransport(behavior: .cancellation)
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        do {
            _ = try await client.evaluateFeatureFlags(for: context())
            #expect(Bool(false))
        } catch is CancellationError {
            // Expected.
        } catch {
            #expect(Bool(false))
        }

        #expect(await fakeTransport.requestCount() == 1)
    }

    @Test("cancellation during suspended transport is preserved")
    func cancellationDuringSuspendedTransportIsPreserved() async throws {
        let fakeTransport = FakePostHogHTTPTransport(behavior: .suspended)
        let client = try PostHogFeatureFlagClient(
            configuration: configuration(),
            transport: fakeTransport
        )

        let task = Task {
            try await client.evaluateFeatureFlags(for: context())
        }

        _ = await fakeTransport.nextRequest()
        task.cancel()
        await fakeTransport.resumeSuspended(statusCode: 200, data: successResponseData())

        do {
            _ = try await task.value
            #expect(Bool(false))
        } catch is CancellationError {
            // Expected.
        } catch {
            #expect(Bool(false))
        }

        #expect(await fakeTransport.requestCount() == 1)
    }
}

private actor AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen {
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func open() {
        guard !isOpen else {
            return
        }

        isOpen = true
        let continuations = waiters
        waiters.removeAll()

        for continuation in continuations {
            continuation.resume()
        }
    }
}

private func configuration() -> PostHogFeatureFlagConfiguration {
    PostHogFeatureFlagConfiguration(projectToken: PostHogProjectToken("ph_project_token"))
}

private func context() -> PostHogFeatureFlagContext {
    PostHogFeatureFlagContext(distinctID: PostHogDistinctID("user-123"))
}

private func successResponseData() -> Data {
    Data(#"{"flags":{"enabled-flag":{"enabled":true}}}"#.utf8)
}
