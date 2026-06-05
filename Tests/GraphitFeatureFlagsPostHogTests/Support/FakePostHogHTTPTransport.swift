import Foundation
@testable import GraphitFeatureFlagsPostHog

actor FakePostHogHTTPTransport: PostHogHTTPTransport {
    enum Behavior: Sendable {
        case response(statusCode: Int, data: Data)
        case failure(FakePostHogHTTPTransportError)
        case cancellation
        case suspended
    }

    private var behavior: Behavior
    private var recordedRequests: [URLRequest] = []
    private var requestWaiters: [CheckedContinuation<URLRequest, Never>] = []
    private var suspendedContinuations: [CheckedContinuation<PostHogHTTPTransportResponse, Error>] = []

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func execute(_ request: URLRequest) async throws -> PostHogHTTPTransportResponse {
        record(request)

        switch behavior {
        case .response(let statusCode, let data):
            return PostHogHTTPTransportResponse(statusCode: statusCode, data: data)
        case .failure(let error):
            throw error
        case .cancellation:
            throw CancellationError()
        case .suspended:
            return try await withCheckedThrowingContinuation { continuation in
                suspendedContinuations.append(continuation)
            }
        }
    }

    func setBehavior(_ behavior: Behavior) {
        self.behavior = behavior
    }

    func requestCount() -> Int {
        recordedRequests.count
    }

    func requests() -> [URLRequest] {
        recordedRequests
    }

    func nextRequest() async -> URLRequest {
        if let request = recordedRequests.first {
            return request
        }

        return await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func resumeSuspended(statusCode: Int, data: Data) {
        let continuations = suspendedContinuations
        suspendedContinuations.removeAll()

        for continuation in continuations {
            continuation.resume(
                returning: PostHogHTTPTransportResponse(statusCode: statusCode, data: data)
            )
        }
    }

    func resumeSuspendedWithCancellation() {
        let continuations = suspendedContinuations
        suspendedContinuations.removeAll()

        for continuation in continuations {
            continuation.resume(throwing: CancellationError())
        }
    }

    private func record(_ request: URLRequest) {
        recordedRequests.append(request)

        let waiters = requestWaiters
        requestWaiters.removeAll()

        for waiter in waiters {
            waiter.resume(returning: request)
        }
    }
}

enum FakePostHogHTTPTransportError: Error, Sendable {
    case failedWithSensitiveDetails(String)
}
