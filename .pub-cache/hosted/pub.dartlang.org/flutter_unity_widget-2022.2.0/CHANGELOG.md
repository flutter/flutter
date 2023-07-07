## 2022.2.0

* Enable AndroidView due to native view improvement in flutter 3.3.0

## 2022.1.7+1

* **BREAKING-CHANGE**:
    * `webUrl` is now removed!
    * You don't need to pass webUrl anymore! This plugin is automatically reading it from your `Uri` -> this means that everything is prepared for your Debug and Release Apps!
* Update dependencies
* Override `webview_flutter` to `^2.8.0` (compatible)

## 2022.1.7

* Fix latest Android Build and Run Performance (see [#643](https://github.com/juicycleff/flutter-unity-view-widget/issues/643) -> Thank to: [@timbotimbo](https://github.com/timbotimbo))
* Add iOS Debug and Release Builds
* Add Android Debug and Release Builds
* Fix iOS XCode Settings for Unity < 2020
* Update actual compatibility to Unity 2022.1.7f1

## 2022.1.1+4

* 🌎 Web is now stable 🚀:
    * Refactored WebView
    * Refactored webUrl -> we are handling now everything for you!
        * use now: `webUrl: http://localhost:${Uri.base.port}` (for Debug only) 
        * for production remember to leave out the last `/` at the end of your url!
    * Refactored Interfaces
    * Use PointerInterceptor if you need stacked widgets (see `/examples` and Readme)
    * Performance Improvements (Communication between HTMLElementView and Flutter)
* 🛠️ Fix Android Crash if you use ARFoundation (ARCore)
* 🛠️ Add updated UnityPackage: `few-2022.1.1-v2.unitypackage` -> use this for latest web and android fixes

## 2022.1.1+3

* Fixed array index range crash on ios

## 2022.1.1+2

* Fixed android screen offset

## 2022.1.1+1

* Fixed issue with unity crashing on ios when screen is pushed into stack

## 2022.1.1

* Fixed issues [#35](https://github.com/juicycleff/flutter-unity-view-widget/pull/595) by [@jamesncl](https://github.com/juicycleff/flutter-unity-view-widget/issues?q=is%3Apr+author%3Ajamesncl)
* Force expensive surface as default for android

## 2022.1.0+6

* Pre Flutter 3.0.0 release

## 2022.1.0+5

* Migrated to Flutter 3.0.0
* Issues with Android with AndroidView now exists

## 2022.1.0+4

* Fixed unity screen turning white on scene load (Android)

## 2022.1.0+2

* Fixed analysis errors

## 2022.1.0+1

* Full support for web
* Fixed android view refocus issue when detached or diposed

## 2022.1.0

* Fixed android freezing with AndroidView
* Fixed FUW export scripts

CHANGELOG.md

## 4.2.5+1

* Removed MultiWindowSupport due to issus on Windows machine export not containing the class

## 4.2.5

* Fixed ios crashing on screen change and on hot reload

## 4.2.4

* Fixed issue with android freezing when screen loses focus

## 4.2.3

* Fixed iOS Run/Build errors: [471](https://github.com/juicycleff/flutter-unity-view-widget/issues/471)

## 4.2.2

* Added support for border radius
* Exposed UI Level for iOS for rendering some UI components ontop of Android

## 4.2.1

* Improved nullsafety

## 4.2.0

* Null safe merged to master

## 4.1.0-null-safe

* Fixed bitcode enabled issue on iOS. [369](https://github.com/juicycleff/flutter-unity-view-widget/issues/369)

## 4.1.0

* Fixed bitcode enabled issue on iOS. [369](https://github.com/juicycleff/flutter-unity-view-widget/issues/369)

## 4.0.2

* Fixing project not compiling though to not overriding class member properly. [@xcxooxl](https://github.com/xcxooxl)
* Removed register-unregister mismatch and removed duplicate calls. [@jakeobrien](https://github.com/jakeobrien)
* Fix for unityDidUnload callback not firing. [@jakeobrien](https://github.com/jakeobrien)
* Docs improvement. [@shinriyo](https://github.com/shinriyo)

## 4.0.1+1

* Fix issue with gestureRecogniser being null

## 4.0.1

* Allow optional use of AndroidView over PlatformViewLink on android

## 4.0.0

* Stable release for v4

## 4.0.0-alpha.4

* Fixed ios method channel ID bug

## 4.0.0-alpha.3

* Small improvements

## 4.0.0-alpha.2

* Fixed communication issues on Android
* Fixed plugin not found on Android

## 4.0.0-alpha.1

* Fixed unload crash on iOS (Requires Unity 2019.4.3 or later)
* Migrated from Objective-c to Swift for iOS
* Migrated from Java to Kotlin on Android
* Fixed issues with channel ID
* Small bug fixes
* Improved iOS performance
* Removed boilerplate code from Android native code

## 3.0.2

* Fixed leaked stream bug

## 3.0.1

* Fixed minor bugs

## 3.0.0

* Lots of breaking changes
* Deprecated APIs
* Fixed [Issue 231](https://github.com/juicycleff/flutter-unity-view-widget/issues/231)
* Fixed [Issue 230](https://github.com/juicycleff/flutter-unity-view-widget/issues/230)


## 2.0.0+2

* fixed some bugs

## 2.0.0+1

* delete duplicated UnityPlayerActivity

## 2.0.0

* Added support for unity scene loaded events [@juicycleff](https://github.com/juicycleff)
* Exposed core unity player api such as quit and unload [@juicycleff](https://github.com/juicycleff)
* Complete rewrite of package to fix bugs [@juicycleff](https://github.com/juicycleff)
* Improved build scripts [@juicycleff](https://github.com/juicycleff)
* Support for large teams with flutter unity cli [@juicycleff](https://github.com/juicycleff)
* Plug and play support for Android [@juicycleff](https://github.com/juicycleff)

## 0.1.6+8

* Breaking change for unityframework iOS

## 0.1.6+7

* Breaking change for unityframework iOS

## 0.1.6+6

* Breaking change for unityframework iOS

## 0.1.6+5

* Reworked onUnityMessage for iOS [@krispypen](https://github.com/krispypen)

## 0.1.6+4

* Improved description

## 0.1.6+3

* Better communication between flutter and unity [@thomas-stockx](https://github.com/thomas-stockx) (Android) & [@krispypen](https://github.com/krispypen) (iOS)
* Fixed issues [#35](https://github.com/snowballdigital/flutter-unity-view-widget/issues/35) by [@thomas-stockx](https://github.com/thomas-stockx)
* Fixed issues [#36](https://github.com/snowballdigital/flutter-unity-view-widget/issues/36) by [@thomas-stockx](https://github.com/thomas-stockx)
* Fixed issues [#33](https://github.com/snowballdigital/flutter-unity-view-widget/issues/33) by [@thomas-stockx](https://github.com/thomas-stockx)
* Fixed issues [#41](https://github.com/snowballdigital/flutter-unity-view-widget/issues/41) by [@thomas-stockx](https://github.com/thomas-stockx)
  
* Fixed issues [#38](https://github.com/snowballdigital/flutter-unity-view-widget/issues/38) by [@krispypen](https://github.com/krispypen)
* Fixed issues [#56](https://github.com/snowballdigital/flutter-unity-view-widget/issues/38) by [@krispypen](https://github.com/krispypen)

## 0.1.6+2

* Fixed issues with `onUnityMessage` [@thomas-stockx](https://github.com/thomas-stockx)

## 0.1.6+1

* Adding Metal renderer support (on iOS) [@krispypen](https://github.com/krispypen)

## 0.1.6

* iOS support for the Unity 2019.3 new export format Unity as a Library [@krispypen](https://github.com/krispypen)

## 0.1.5

* Android support for the Unity 2019.3 new export format Unity as a Library [@thomas-stockx](https://github.com/thomas-stockx)

## 0.1.4

* Support for AR on Android thanks to [@thomas-stockx](https://github.com/thomas-stockx)

## 0.1.3+4

* Change input source of Flutter touch events so they work in Unity [@thomas-stockx](https://github.com/thomas-stockx)
* Instructions on how to implement Vuforia AR
* Fix postMessage throwing exceptions on Android [@thomas-stockx](https://github.com/thomas-stockx)
* Add video tutorial, replace `unity-player` with `unity-classes` in example [@lorant-csonka-planorama](https://github.com/lorant-csonka-planorama)
* Remove java and UnityPlayer changes to the windowmanager [@thomas-stockx](https://github.com/thomas-stockx)
