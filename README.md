# CleverTap ZeroPii SDK for iOS

## Overview

CleverTap ZeroPii SDK provides a secure way to tokenize Personally Identifiable Information (PII) in your iOS applications. By replacing sensitive data with format-preserving tokens, you can minimize the exposure of sensitive information while maintaining data utility.

## Features

- **Tokenization**: Replace sensitive data with format-preserving tokens
- **Batch Operations**: Efficiently process multiple values in a single network call (up to 1,000 values)
- **Encryption in Transit**: Request and response payloads are encrypted while being transmitted over the network
- **Bring-Your-Own Auth**: No OAuth credentials in the SDK — your app supplies access tokens via the `AccessTokenProvider` protocol, keeping authentication logic under your control
- **ObjC / Swift / SwiftUI Compatible**: All public APIs are annotated with `@objc` and work across Objective-C, Swift, and SwiftUI apps

## Requirements

| | |
|---|---|
| **iOS** | 13.0+ |
| **Swift** | 5.0+ |
| **Xcode** | 15.0+ |

The SDK has **no third-party dependencies**.

---

## Installation

### Swift Package Manager

In Xcode, go to **File → Add Package Dependencies** and enter the repository URL.

Or add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CleverTap/clevertap-ios-vault-sdk.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["CleverTapZeroPiiSDK"]
    )
]
```

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'CleverTapZeroPiiSDK', '~> 1.0'
```

Then run:

```bash
pod install
```

---

## Quick Start

### 1. Implement `AccessTokenProvider`

The SDK does not handle authentication itself. You supply a fresh bearer token whenever the SDK needs one by implementing the `AccessTokenProvider` protocol.

**Swift / SwiftUI**

```swift
import CleverTapZeroPiiSDK

class MyTokenProvider: AccessTokenProvider {
    func fetchToken(completion: @escaping (AccessTokenInfo?, Error?) -> Void) {
        // Fetch a token from your auth system, then call completion exactly once.
        MyAuthService.shared.getToken { token, expiresIn, error in
            if let error = error {
                completion(nil, error)
            } else {
                let info = AccessTokenInfo(token: token!, expiresInSeconds: expiresIn)
                completion(info, nil)
            }
        }
    }
}
```

**Objective-C**

```objc
#import <CleverTapZeroPiiSDK/CleverTapZeroPiiSDK-Swift.h>

@interface MyTokenProvider : NSObject <AccessTokenProvider>
@end

@implementation MyTokenProvider

- (void)fetchTokenWithCompletion:(void (^)(AccessTokenInfo * _Nullable, NSError * _Nullable))completion {
    [MyAuthService.shared getTokenWithCallback:^(NSString *token, NSInteger expiresIn, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            AccessTokenInfo *info = [[AccessTokenInfo alloc] initWithToken:token expiresInSeconds:expiresIn];
            completion(info, nil);
        }
    }];
}

@end
```

> **Important:** You **must** call `completion` exactly once — either with a valid `AccessTokenInfo` on success, or with an `Error` on failure. Calling it zero times will cause the SDK to hang indefinitely; calling it more than once has undefined behaviour.

---

### 2. Initialize the SDK

Initialize once, as early as possible — typically in `AppDelegate` or your SwiftUI `App` entry point.

**Swift (AppDelegate)**

```swift
import CleverTapZeroPiiSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        ZeroPiiSDK.initialize(
            tokenProvider: MyTokenProvider(),
            apiUrl: "https://your-api-base-url.com/"
        )

        // Optional: enable logging during development
        ZeroPiiSDK.initialize(
            tokenProvider: MyTokenProvider(),
            apiUrl: "https://your-api-base-url.com/",
            logLevel: .debug
        )

        return true
    }
}
```

**SwiftUI (App entry point)**

```swift
import SwiftUI
import CleverTapZeroPiiSDK

@main
struct MyApp: App {

    init() {
        ZeroPiiSDK.initialize(
            tokenProvider: MyTokenProvider(),
            apiUrl: "https://your-api-base-url.com/"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Objective-C (AppDelegate)**

```objc
#import <CleverTapZeroPiiSDK/CleverTapZeroPiiSDK-Swift.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [ZeroPiiSDK initializeWithTokenProvider:[MyTokenProvider new]
                                     apiUrl:@"https://your-api-base-url.com/"];
    return YES;
}

@end
```

> **Note:** You **must** call `initialize()` before using any other SDK methods. Calling `getInstance()` before initialization will cause a fatal error.

---

### 3. Tokenize a Single Value

**Swift**

```swift
let sdk = ZeroPiiSDK.getInstance()

sdk.tokenizeString("user@example.com") { result in
    if result.isSuccess {
        let token       = result.token!        // the generated token
        let wasExisting = result.exists        // true if this value was already tokenized before
        let isNew       = result.newlyCreated  // true if a new token was created
        let dataType    = result.dataType      // "string" or "number"
        print("Token: \(token)")
    } else {
        print("Tokenization failed: \(result.errorMessage ?? "unknown error")")
    }
}

// Numeric types
sdk.tokenizeInt(42) { result in ... }
sdk.tokenizeLong(9876543210) { result in ... }
sdk.tokenizeFloat(3.14) { result in ... }
sdk.tokenizeDouble(2.71828) { result in ... }
sdk.tokenizeBool(true) { result in ... }
```

**SwiftUI**

```swift
import SwiftUI
import CleverTapZeroPiiSDK

struct ContentView: View {
    @State private var token: String = ""

    var body: some View {
        VStack {
            Text(token.isEmpty ? "No token yet" : "Token: \(token)")
            Button("Tokenize") {
                ZeroPiiSDK.getInstance().tokenizeString("user@example.com") { result in
                    // Callback is delivered on the main thread — safe to update @State directly.
                    if result.isSuccess {
                        token = result.token ?? ""
                    }
                }
            }
        }
    }
}
```

**Objective-C**

```objc
[[ZeroPiiSDK getInstance] tokenizeString:@"user@example.com"
                               callback:^(TokenizeResult *result) {
    if (result.isSuccess) {
        NSLog(@"Token: %@", result.token);
    } else {
        NSLog(@"Error: %@", result.errorMessage);
    }
}];
```

---

### 4. Batch Tokenization

Process multiple values in a single API call. Maximum **1,000 values per batch**.

**Swift**

```swift
let emails = ["alice@example.com", "bob@example.com", "carol@example.com"]

ZeroPiiSDK.getInstance().batchTokenizeStringValues(emails) { result in
    if result.isSuccess {
        let summary = result.summary!
        print("Processed : \(summary.processedCount)")
        print("New tokens: \(summary.newlyCreatedCount)")
        print("Existing  : \(summary.existingCount)")

        for item in result.results {
            print("\(item.originalValue) → \(item.token)")
        }
    } else {
        print("Batch failed: \(result.errorMessage ?? "unknown error")")
    }
}

// Other supported types
ZeroPiiSDK.getInstance().batchTokenizeIntValues([1, 2, 3]) { result in ... }
ZeroPiiSDK.getInstance().batchTokenizeLongValues([10_000_000_000]) { result in ... }
ZeroPiiSDK.getInstance().batchTokenizeFloatValues([1.1, 2.2]) { result in ... }
ZeroPiiSDK.getInstance().batchTokenizeDoubleValues([1.111, 2.222]) { result in ... }
ZeroPiiSDK.getInstance().batchTokenizeBoolValues([true, false]) { result in ... }
```

**Objective-C**

```objc
NSArray<NSString *> *emails = @[@"alice@example.com", @"bob@example.com"];

[[ZeroPiiSDK getInstance] batchTokenizeStringValues:emails
                                      callback:^(BatchTokenizeResult *result) {
    if (result.isSuccess) {
        NSLog(@"Processed: %ld", result.summary.processedCount);
        for (BatchTokenItem *item in result.results) {
            NSLog(@"%@ → %@", item.originalValue, item.token);
        }
    } else {
        NSLog(@"Batch error: %@", result.errorMessage);
    }
}];
```

---

### Thread Safety Note

**Callbacks are always delivered on the main thread**, so it is safe to update your UI directly from the callback without dispatching to `DispatchQueue.main`.

---

## API Reference

### Initialization

#### `initialize(tokenProvider:apiUrl:logLevel:)`

```swift
@discardableResult
public static func initialize(
    tokenProvider: AccessTokenProvider,
    apiUrl: String,
    logLevel: ZeroPiiLogLevel = .off
) -> ZeroPiiSDK
```

| Parameter | Description |
|---|---|
| `tokenProvider` | Your implementation of `AccessTokenProvider` that supplies bearer tokens |
| `apiUrl` | Base URL for the tokenization API (include trailing slash) |
| `logLevel` | Logging verbosity. Default: `.off` |

#### `initialize(tokenProvider:apiUrl:)` *(ObjC convenience)*

```swift
@discardableResult
public static func initialize(
    tokenProvider: AccessTokenProvider,
    apiUrl: String
) -> ZeroPiiSDK
```

Convenience overload without `logLevel` for Objective-C callers, which cannot use Swift default parameter values. Equivalent to calling the above with `logLevel: .off`.

#### `getInstance()`

```swift
public static func getInstance() -> ZeroPiiSDK
```

Returns the singleton. Crashes with a fatal error if called before `initialize()`.

---

### Single-Value Tokenization

All methods follow the same pattern — execute on a background thread and deliver the callback on the main thread.

```swift
func tokenizeString(_ value: String,  callback: @escaping (TokenizeResult) -> Void)
func tokenizeInt   (_ value: Int,     callback: @escaping (TokenizeResult) -> Void)
func tokenizeLong  (_ value: Int64,   callback: @escaping (TokenizeResult) -> Void)
func tokenizeFloat (_ value: Float,   callback: @escaping (TokenizeResult) -> Void)
func tokenizeDouble(_ value: Double,  callback: @escaping (TokenizeResult) -> Void)
func tokenizeBool  (_ value: Bool,    callback: @escaping (TokenizeResult) -> Void)
```

---

### Batch Tokenization

```swift
func batchTokenizeStringValues(_ values: [String], callback: @escaping (BatchTokenizeResult) -> Void)
func batchTokenizeIntValues   (_ values: [Int],    callback: @escaping (BatchTokenizeResult) -> Void)
func batchTokenizeLongValues  (_ values: [Int64],  callback: @escaping (BatchTokenizeResult) -> Void)
func batchTokenizeFloatValues (_ values: [Float],  callback: @escaping (BatchTokenizeResult) -> Void)
func batchTokenizeDoubleValues(_ values: [Double], callback: @escaping (BatchTokenizeResult) -> Void)
func batchTokenizeBoolValues  (_ values: [Bool],   callback: @escaping (BatchTokenizeResult) -> Void)
```

> **Batch limits:** Maximum 1,000 values per call. Exceeding this limit returns an error result immediately without making a network request. Empty arrays also return an error result immediately.

---

## Data Types

### `AccessTokenProvider`

```swift
@objc public protocol AccessTokenProvider {
    func fetchToken(completion: @escaping (AccessTokenInfo?, Error?) -> Void)
}
```

Implement this protocol to bridge your app's authentication system to the SDK.

### `AccessTokenInfo`

```swift
@objc public class AccessTokenInfo: NSObject {
    public let token: String           // The bearer access token
    public let expiresInSeconds: Int   // Seconds until expiry (from now)
}
```

### `TokenizeResult`

```swift
@objc public class TokenizeResult: NSObject {
    public let isSuccess: Bool       // true on success
    public let token: String?        // The generated token (nil on error)
    public let exists: Bool          // true if this value was already tokenized
    public let newlyCreated: Bool    // true if a new token was created
    public let dataType: String?     // "string" or "number" (nil on error)
    public let errorMessage: String? // Human-readable error (nil on success)
    public let httpStatusCode: NSNumber? // HTTP status code on server error, nil for SDK-level errors
}
```

### `BatchTokenizeResult`

```swift
@objc public class BatchTokenizeResult: NSObject {
    public let isSuccess: Bool               // true on success
    public let results: [BatchTokenItem]     // Individual item results (empty on error)
    public let summary: BatchTokenizeSummary?// Aggregate stats (nil on error)
    public let errorMessage: String?         // Human-readable error (nil on success)
    public let httpStatusCode: NSNumber?     // HTTP status code on server error, nil for SDK-level errors
}
```

### `BatchTokenItem`

```swift
@objc public class BatchTokenItem: NSObject {
    public let originalValue: String  // The original input value
    public let token: String          // The generated token
    public let exists: Bool           // true if the token already existed
    public let newlyCreated: Bool     // true if a new token was created
    public let dataType: String?      // "string" or "number"
}
```

### `BatchTokenizeSummary`

```swift
@objc public class BatchTokenizeSummary: NSObject {
    public let processedCount: Int     // Total values processed
    public let existingCount: Int      // Values that already had a token
    public let newlyCreatedCount: Int  // New tokens created in this call
}
```

### Log Levels (`ZeroPiiLogLevel`)

```swift
@objc public enum ZeroPiiLogLevel: Int {
    case off     = 0  // No logging (default)
    case error   = 1  // Errors only
    case info    = 2  // Errors + informational messages
    case debug   = 3  // Errors + info + debug trace (use during development only)
}
```

Logs are written via `os_log` and are visible in **Xcode's Console** and the **macOS Console app** under the `CleverTap` subsystem and `CT-ZeroPiiSDK` category.

---

## Objective-C Integration Notes

All public classes, protocols, and enums are annotated with `@objc` and subclass `NSObject`, making them fully accessible from Objective-C.

**Import the generated Swift header:**

```objc
// CocoaPods
#import <CleverTapZeroPiiSDK/CleverTapZeroPiiSDK-Swift.h>

// SPM (module-qualified)
@import CleverTapZeroPiiSDK;
```

**Checking the result in ObjC** — since Swift enums with associated values cannot be used in ObjC, all results are returned as `NSObject` subclasses with boolean flags:

```objc
[[ZeroPiiSDK getInstance] tokenizeString:@"user@example.com"
                               callback:^(TokenizeResult *result) {
    if (result.isSuccess) {
        NSLog(@"Token: %@, newly created: %d", result.token, result.newlyCreated);
    } else {
        NSLog(@"Failed: %@", result.errorMessage);
    }
}];
```

---

## Sample App

A sample application demonstrating SDK integration is included in the `ZeroPIISample/` directory of the repository. Open `ZeroPIISample/ZeroPIISample.xcodeproj` in Xcode to explore it.
