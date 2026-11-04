Pod::Spec.new do |s|
  s.name             = 'CleverTapZeroPiiSDK'
  s.version          = '1.1.0'
  s.summary          = 'CleverTap Zero PII SDK — tokenize sensitive PII data with AES-256-GCM encryption in transit.'

  s.description      = <<-DESC
    CleverTap Zero PII SDK provides tokenization services for Personally Identifiable Information (PII).
    It encrypts data in transit using AES-256-GCM (CryptoKit) and falls back gracefully to plain
    tokenization when encryption is unavailable or rejected by the backend. Compatible with
    Swift, SwiftUI, and Objective-C apps.

    NOTICE: CocoaPods trunk becomes read-only on December 2, 2026. To keep
    receiving CleverTap updates through CocoaPods, add these lines to your Podfile:
      source 'https://github.com/CleverTap/podspecs.git'
      source 'https://cdn.cocoapods.org/'
    Existing installs are unaffected. See the README.
  DESC

  s.homepage         = 'https://github.com/CleverTap/clevertap-ios-zeropii-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'CleverTap' => 'sdk@clevertap.com' }
  s.source           = { :git => 'https://github.com/CleverTap/clevertap-ios-zeropii-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_versions        = ['5.0']

  s.source_files = 'clevertap-ios-zeropii-sdk/clevertap-ios-zeropii-sdk/**/*.swift'

  # CryptoKit and Foundation are system frameworks available on iOS 15+; no explicit linkage needed.
  s.frameworks = 'Foundation'

  s.pod_target_xcconfig = {
    'SWIFT_VERSION'              => '5.0',
    'SWIFT_INSTALL_OBJC_HEADER'  => 'YES'
  }
end
