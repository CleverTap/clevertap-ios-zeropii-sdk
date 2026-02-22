// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleverTapZeroPiiSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CleverTapZeroPiiSDK",
            targets: ["CleverTapZeroPiiSDK"]
        )
    ],
    targets: [
        .target(
            name: "CleverTapZeroPiiSDK",
            path: "clevertap-ios-vault-sdk/clevertap-ios-zeropii-sdk",
            exclude: ["clevertap_ios_zeropii_sdk.h"]
        )
    ]
)
