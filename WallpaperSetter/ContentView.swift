//
//  ContentView.swift
//  WallpaperSetter
//
//  Created by Skitty on 9/3/22.
//

import SwiftUI

struct ContentView: View {

    enum WallpaperLoction: Int {
        case lockScreen = 1
        case homeScreen = 2
        case both = 3
    }

    @State private var settingDarkImage: Bool = false
    @State private var inputImage: UIImage?

    @State private var hasLightImage: Bool = false
    @State private var hasDarkImage: Bool = false

    @State private var lightImage = UIImage(named: "placeholder")!
    @State private var darkImage = UIImage(named: "placeholder")!

    @State private var perspectiveZoom: Bool = true
    @State private var downscaleImages: Bool = false

    @State private var showingImagePicker: Bool = false
    @State private var showingLocationSelect: Bool = false
    @State private var showingSelectAlert: Bool = false
    @State private var showingErrorAlert: Bool = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 0) {
                        Spacer()
                        Image(uiImage: lightImage)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: UIScreen.main.bounds.width * (244 / UIScreen.main.bounds.height),
                                height: 244
                            )
                            .clipped()
                            .border(Color(UIColor.quaternarySystemFill))

                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 12) // fix for spacing bug not centering

                        Image(uiImage: darkImage)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: UIScreen.main.bounds.width * (244 / UIScreen.main.bounds.height),
                                height: 244
                            )
                            .clipped()
                            .border(Color(UIColor.quaternarySystemFill))
                        Spacer()
                    }
                    .padding(.vertical)
                    Toggle("Perspective Zoom", isOn: $perspectiveZoom)
//                    Toggle("Downscale Images", isOn: $downscaleImages) // I don't think this is really necessary
                }
                Section {
                    Button("Set Light Wallpaper") {
                        settingDarkImage = false
                        showingImagePicker = true
                    }
                    Button("Set Dark Wallpaper") {
                        settingDarkImage = true
                        showingImagePicker = true
                    }
                }
                Section {
                    Button("Set Wallpaper") {
                        showingLocationSelect = true
                    }
                    .confirmationDialog("Select location", isPresented: $showingLocationSelect, titleVisibility: .hidden) {
                        Button("Home Screen") {
                            setWallpaper(location: .homeScreen)
                        }
                        Button("Lock Screen") {
                            setWallpaper(location: .lockScreen)
                        }
                        Button("Both") {
                            setWallpaper(location: .both)
                        }
                    }
                }
            }
            .navigationTitle("WallpaperSetter")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .alert("Select Wallpapers", isPresented: $showingSelectAlert) {
                Button("OK", role: .cancel) {
                    showingSelectAlert = false
                }
            } message: {
                Text("Please select a wallpaper before setting.")
            }
            .alert("Failed", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {
                    showingSelectAlert = false
                }
            } message: {
                Text("Encountered an error when setting wallpaper.")
            }
            .onChange(of: inputImage) { _ in loadImage() }
            .onAppear {
                loadWallpapers()
            }
        }
    }

    // doesn't work without extra perms, which we don't have
    func loadWallpapers() {
        if let lightWallpaper = UIImage(contentsOfFile: "/var/mobile/Library/SpringBoard/LockBackgroundThumbnail.jpg") {
            lightImage = lightWallpaper
            darkImage = lightWallpaper
            hasLightImage = true
            hasDarkImage = true
        }
        if let darkWallpaper = UIImage(contentsOfFile: "/var/mobile/Library/SpringBoard/LockBackgroundThumbnaildark.jpg") {
            darkImage = darkWallpaper
            hasDarkImage = true
        }
    }

    // load inputImage from picker
    func loadImage() {
        guard let inputImage = inputImage else {
            return
        }
        self.inputImage = nil
        if settingDarkImage {
            darkImage = downscaleImages ? downscale(image: inputImage) : inputImage
            hasDarkImage = true
        } else {
            lightImage = downscaleImages ? downscale(image: inputImage) : inputImage
            hasLightImage = true
        }
    }

    func downscale(image: UIImage) -> UIImage {
        let factor = 1024 / image.size.height
        let size = CGSize(width: image.size.width * factor, height: 1024)

        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }

    func setWallpaper(location: WallpaperLoction) {
        // ensure a wallpaper has been chosen
        if !hasLightImage && hasDarkImage {
            lightImage = darkImage
            hasLightImage = true
        }
        guard hasLightImage else {
            showingSelectAlert = true
            return
        }
        if !hasDarkImage {
            darkImage = lightImage
            hasDarkImage = true
        }

        // load private frameworks
        let frameworkPath: String
        #if TARGET_OS_SIMULATOR
            frameworkPath = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks"
        #else
            frameworkPath = "/System/Library/PrivateFrameworks"
        #endif

        let sbFoundation = dlopen(frameworkPath + "/SpringBoardFoundation.framework/SpringBoardFoundation", RTLD_LAZY)
        let sbUIServices = dlopen(frameworkPath + "/SpringBoardUIServices.framework/SpringBoardUIServices", RTLD_LAZY)

        guard
            let SBFWallpaperOptions = NSClassFromString("SBFWallpaperOptions"),
            let pointer = dlsym(sbUIServices, "SBSUIWallpaperSetImages"),
            let SBSUIWallpaperSetImages = unsafeBitCast(
                pointer,
                to: (@convention(c) (_: NSDictionary, _: NSDictionary, _: Int, _: Int) -> Int)?.self
            )
        else {
            showingErrorAlert = true
            return
        }

        // set wallpaper options
        let setModeSelector = NSSelectorFromString("setWallpaperMode:")
        let setParallaxSelector = NSSelectorFromString("setParallaxFactor:")
        let setNameSelector = NSSelectorFromString("setName:")

        let lightOptions = SBFWallpaperOptions.alloc()
        invokeInt(setModeSelector, lightOptions, 1)
        invokeDouble(setParallaxSelector, lightOptions, perspectiveZoom ? 1 : 0)
        invokeAny(setNameSelector, lightOptions, NSString("1234.WallpaperLoader Light"))

        let darkOptions = SBFWallpaperOptions.alloc()
        invokeInt(setModeSelector, darkOptions, 2)
        invokeDouble(setParallaxSelector, darkOptions, perspectiveZoom ? 1 : 0)
        invokeAny(setNameSelector, darkOptions, NSString("1234.WallpaperLoader Dark"))

        let imagesDict = [
            "light": lightImage,
            "dark": darkImage
        ]

        let optionsDict = [
            "light" : lightOptions,
            "dark": darkOptions
        ]

        // set wallpaper
        _ = SBSUIWallpaperSetImages(
            NSDictionary(dictionary: imagesDict),
            NSDictionary(dictionary: optionsDict),
            location.rawValue,
            UIUserInterfaceStyle.dark.rawValue
        )

        dlclose(sbFoundation)
        dlclose(sbUIServices)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
