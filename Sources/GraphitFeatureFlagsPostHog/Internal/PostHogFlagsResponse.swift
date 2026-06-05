import Foundation

internal struct PostHogFlagsResponse: Decodable, Sendable {
    internal let flags: [String: Flag]
    internal let errorsWhileComputingFlags: Bool
    internal let quotaLimited: [String]
    internal let requestID: String?

    internal static func decode(from data: Data) throws -> PostHogFlagsResponse {
        do {
            return try JSONDecoder().decode(PostHogFlagsResponse.self, from: data)
        } catch let error as PostHogFeatureFlagError {
            throw error
        } catch {
            throw PostHogFeatureFlagError.invalidResponse(
                "Response JSON is malformed or does not match the expected /flags shape."
            )
        }
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard container.contains(.flags) else {
            throw PostHogFeatureFlagError.invalidResponse("Response must include a flags object.")
        }

        self.flags = try container.decode([String: Flag].self, forKey: .flags)

        if container.contains(.errorsWhileComputingFlags) {
            self.errorsWhileComputingFlags = try container.decode(Bool.self, forKey: .errorsWhileComputingFlags)
        } else {
            self.errorsWhileComputingFlags = false
        }

        if container.contains(.quotaLimited) {
            self.quotaLimited = try container.decode([String].self, forKey: .quotaLimited)
        } else {
            self.quotaLimited = []
        }

        if container.contains(.requestID) {
            self.requestID = try container.decode(String.self, forKey: .requestID)
        } else {
            self.requestID = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case flags
        case errorsWhileComputingFlags
        case quotaLimited
        case requestID = "requestId"
    }

    internal struct Flag: Decodable, Sendable {
        internal let key: String?
        internal let enabled: Bool
        internal let variant: String?

        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if container.contains(.key) {
                self.key = try container.decode(String.self, forKey: .key)
            } else {
                self.key = nil
            }

            guard container.contains(.enabled) else {
                throw PostHogFeatureFlagError.invalidResponse(
                    "Each flag object must include a Boolean enabled field."
                )
            }

            self.enabled = try container.decode(Bool.self, forKey: .enabled)

            guard enabled else {
                self.variant = nil
                return
            }

            if !container.contains(.variant) {
                self.variant = nil
            } else if try container.decodeNil(forKey: .variant) {
                self.variant = nil
            } else {
                self.variant = try container.decode(String.self, forKey: .variant)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case key
            case enabled
            case variant
        }
    }
}
