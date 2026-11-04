## CleverTap ZeroPii SDK CHANGE LOG

### Version 1.1.0

#### Added

* Xcode 27 and iOS 27 support: The SDK builds with Xcode 27 and runs on iOS 27.
   * Minimum deployment target is now iOS 15.0 (previously iOS 13.0). Xcode 27 does not build targets below this range.
   * CocoaPods users may also need a `post_install` hook that raises every pod target to iOS 15, because other dependencies in the Podfile can carry their own lower minimums. The ZeroPii SDK itself has no third-party dependencies.
   * Apps built with the iOS 26 or 27 SDK must adopt the UIScene lifecycle. The sample apps (`ZeroPIISample`, `ZeroPIIObjCSample`) already use it. No ZeroPii feature is affected, because the SDK presents no UI and hooks no app lifecycle callbacks.
   * See [the iOS 27 Support doc](https://github.com/CleverTap/clevertap-ios-zeropii-sdk/blob/master/docs/iOS27Support.md) for the migration steps.

### Version 1.0.0 (12 March 2026)

#### 🎉 Initial Release

The CleverTap ZeroPii SDK provides secure tokenization of Personally Identifiable Information (PII) for iOS applications.

#### Features

##### Core Tokenization
- **Single Value Tokenization**: Convert sensitive PII into format-preserving tokens
- **Type-Safe APIs**: Support for multiple data types — `String`, `Int`, `Long`, `Float`, `Double`, and `Boolean`

##### Batch Operations
- **Batch Tokenization**: Process up to 1,000 values in a single request for all supported data types
- **Detailed Results**: Get per-item token results along with a summary of processed, existing, and newly created token counts
