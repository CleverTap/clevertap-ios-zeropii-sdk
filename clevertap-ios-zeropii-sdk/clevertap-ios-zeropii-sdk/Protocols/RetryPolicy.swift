//
//  RetryPolicy.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 24/02/26.
//

import Foundation

/// Controls retry behavior for failed tokenization network requests.
///
/// Implement this protocol to customize when and how often the SDK retries
/// failed API calls. Inject your implementation via
/// `ZeroPiiSDK.initialize(tokenProvider:apiUrl:logLevel:retryPolicy:)`.
///
/// - Note: 401 Unauthorized responses are handled internally by the SDK (token refresh
///   + immediate retry) and are **never** passed to this policy.
///
/// **Example — aggressive retry for unreliable networks:**
/// ```swift
/// class AggressiveRetryPolicy: NSObject, RetryPolicy {
///     func shouldRetry(attempt: Int, httpStatusCode: NSNumber?) -> Bool {
///         return attempt < 3
///     }
///     func retryDelayMs(attempt: Int) -> Int {
///         return 500 * (attempt + 1) // 500ms, 1000ms, 1500ms
///     }
/// }
/// ```
@objc public protocol RetryPolicy: AnyObject {

    /// Determines whether the SDK should retry a failed request.
    ///
    /// Called after each failed attempt before the next retry. Return `false` to stop
    /// retrying and surface the error to the app via the tokenization callback.
    ///
    /// - Parameters:
    ///   - attempt: 0-based attempt index. `0` = after the first failure (before the first retry).
    ///   - httpStatusCode: HTTP status code of the failed response, or `nil` if the failure
    ///     was a network error (no HTTP response received, e.g. timeout or no connectivity).
    /// - Returns: `true` to retry, `false` to stop and deliver the error to the callback.
    func shouldRetry(attempt: Int, httpStatusCode: NSNumber?) -> Bool

    /// Returns how long to wait before the next retry attempt.
    ///
    /// Only called when `shouldRetry(attempt:httpStatusCode:)` returns `true`.
    ///
    /// - Parameter attempt: 0-based attempt index (same value passed to `shouldRetry`).
    /// - Returns: Delay in milliseconds. Return `0` for an immediate retry.
    func retryDelayMs(attempt: Int) -> Int
}

/// Default retry policy used by the SDK when no custom policy is provided.
///
/// Retries on server errors (500, 502, 503, 504), rate limiting (429), and network
/// errors (`nil` status code). Uses exponential backoff: 2 s, 4 s, 8 s, …
///
/// | Attempt | Delay  |
/// |---------|--------|
/// | 0       | 2000 ms |
/// | 1       | 4000 ms |
/// | 2       | 8000 ms |
class DefaultRetryPolicy: NSObject, RetryPolicy {

    private let maxRetries: Int
    private let retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]

    /// - Parameter maxRetries: Maximum number of retry attempts. Defaults to `1`.
    init(maxRetries: Int = 1) {
        self.maxRetries = maxRetries
    }

    func shouldRetry(attempt: Int, httpStatusCode: NSNumber?) -> Bool {
        guard attempt < maxRetries else { return false }
        // nil = network error (no HTTP response received) — always retryable
        guard let code = httpStatusCode else { return true }
        return retryableStatusCodes.contains(code.intValue)
    }

    func retryDelayMs(attempt: Int) -> Int {
        // Exponential backoff: 1000 * 2^(attempt + 1) → 2000, 4000, 8000, … ms
        return 1000 * (1 << (attempt + 1))
    }
}
