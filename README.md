# WallpaperSetter
iOS application for setting separate light and dark mode wallpapers. Usable with [TrollStore](https://github.com/opa334/TrollStore) on iOS 14-15.1.1.

## Building
WallpaperSetter requires the `com.apple.springboard.wallpaper-access` entitlement, meaning you won't be able to codesign it with an Apple Developer account to run on a real device. You will need to use `xcodebuild` to build without codesigning.
```sh
xcodebuild build CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```
To package it, move the resulting .app in the `build/Release-iphoneos` directory into a `Payload` folder, zip it, and then rename to an ipa file.

Running on the simulator should work fine.
