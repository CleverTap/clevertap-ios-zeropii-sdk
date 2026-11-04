# Xcode 27 / iOS 27 Support

The CleverTap ZeroPii SDK builds with **Xcode 27** and runs on **iOS 27**. Two things changed that may require action in your app:

1. The **minimum deployment target** was raised from iOS 13 to **iOS 15** (Xcode 27 no longer builds targets below its supported range).
2. Apps must adopt the **UIScene lifecycle** (required by iOS 26+ when built with the iOS 26/27 SDK).

---

## 1. Minimum deployment target

| Platform | Previous | New minimum |
| --- | --- | --- |
| iOS | 13.0 | **15.0** |

If your app targets a version below iOS 15, raise its deployment target. Xcode 27 fails the build with an error like:

```
error: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0,
but the range of supported deployment target versions is 15.0 to 27.x.
```

No source changes are needed on your side. The SDK uses `CryptoKit` and `Foundation` only, both available well below iOS 15, so the raised floor does not remove any functionality.

---

## 2. CocoaPods: bump your pod deployment targets

The ZeroPii SDK has no third-party dependencies, so the pod itself is clean at iOS 15. Other pods in your `Podfile` may still declare an older minimum, and Xcode 27 fails to build **any** target below iOS 15. Setting `platform :ios, '15.0'` is not always enough, because each pod can carry its own lower deployment target.

Add a `post_install` hook to your `Podfile` that raises every generated pod target, then run `pod install` again:

```ruby
platform :ios, '15.0'
use_frameworks!

target 'YourApp' do
  pod 'CleverTapZeroPiiSDK'
  # ...
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
```

> Already have a `post_install` block? Add the `IPHONEOS_DEPLOYMENT_TARGET` line inside it. Do not declare a second `post_install`.

### Swift Package Manager

Nothing to do beyond raising your app target to iOS 15. `Package.swift` already declares `.iOS(.v15)`.

---

## 3. Adopt the UIScene lifecycle

Starting with iOS 26, apps built with the iOS 26/27 SDK **must** use the `UIScene` lifecycle. An app that still uses the legacy app-delegate, window-based lifecycle - an `AppDelegate` with a `window` property, a `UIMainStoryboardFile` in `Info.plist`, and no scene manifest - **crashes at launch** on iOS 26 and later.

This is an app-side requirement, not a ZeroPii SDK change. The SDK presents no UI of its own and holds no reference to your window, so it works under either lifecycle. Your app still has to adopt the scene lifecycle to run on iOS 27.

### You do not need to do anything if

- Your app uses the **SwiftUI `App` lifecycle** (`@main struct … : App { WindowGroup { … } }`). It is already scene-based.
- Your app already has a `UISceneDelegate` and a `UIApplicationSceneManifest`.

### If your app uses an app-delegate-only (storyboard) lifecycle

#### Step 1 - Add a scene manifest to `Info.plist`

Add `UIApplicationSceneManifest` and **remove** the existing `UIMainStoryboardFile` entry:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <!-- Swift: $(PRODUCT_MODULE_NAME).SceneDelegate   ObjC: SceneDelegate -->
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

#### Step 2 - Add a `SceneDelegate` that creates the window

Move window creation out of the app delegate and into a scene delegate.

**Swift**

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
```

**Objective-C**

```objc
@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) { return; }
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
}

@end
```

#### Step 3 - Move lifecycle callbacks to the scene delegate

Under the scene lifecycle these callbacks move off the app delegate. Forward any that your app uses:

| App delegate (legacy) | Scene delegate (new) |
| --- | --- |
| `application(_:open:options:)` | `scene(_:openURLContexts:)` |
| `application(_:continue:restorationHandler:)` | `scene(_:continue:)` |
| `applicationWillEnterForeground(_:)` | `sceneWillEnterForeground(_:)` |
| `applicationDidEnterBackground(_:)` | `sceneDidEnterBackground(_:)` |

The ZeroPii SDK does not hook any of these callbacks, so no SDK call sites need to move.

---

## Reference - sample apps

The sample apps in this repository already run under the scene lifecycle:

| Sample | Lifecycle | Scene setup |
| --- | --- | --- |
| `ZeroPIISample` | SwiftUI `App` | none needed (already scene-based) |
| `ZeroPIIObjCSample` | UIKit (ObjC) | `SceneDelegate` + scene manifest in `Info.plist` |
