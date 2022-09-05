# WallpaperSetter
iOS application for setting separate light and dark mode wallpapers. Usable with [TrollStore](https://github.com/opa334/TrollStore) on iOS 14-15.1.1.

## Building
WallpaperSetter requires the `com.apple.springboard.wallpaper-access` entitlement, meaning you won't be able to codesign it with an Apple Developer account to run on a real device. You will need to use `xcodebuild` to build without codesigning.
```sh
xcodebuild build CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```
To package it, copy the resulting .app in the `build/Release-iphoneos` directory into a `Payload` folder, fakesign it, zip it, and then rename to an ipa file.
```sh
cd build/Release-iphoneos/
mkdir Payload
ldid -S../../WallpaperSetter/WallpaperSetter.entitlements WPSetter.app
cp -r WPSetter.app Payload
zip -r WallpaperSetter.ipa Payload
```

Running on the simulator should work fine.
