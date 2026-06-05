import Foundation

internal protocol PostHogHTTPTransport: Sendable {
    func execute(_ request: URLRequest) async throws -> PostHogHTTPTransportResponse
}

internal struct PostHogHTTPTransportResponse: Sendable {
    internal let statusCode: Int
    internal let data: Data

    internal init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

internal final class URLSessionPostHogHTTPTransport: PostHogHTTPTransport {
    private let session: URLSession

    internal init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil

        self.session = URLSession(configuration: configuration)
    }

    internal func execute(_ request: URLRequest) async throws -> PostHogHTTPTransportResponse {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLSessionPostHogHTTPTransportError.nonHTTPResponse
        }

        return PostHogHTTPTransportResponse(
            statusCode: httpResponse.statusCode,
            data: data
        )
    }
}

private enum URLSessionPostHogHTTPTransportError: Error, Sendable {
    case nonHTTPResponse
}
