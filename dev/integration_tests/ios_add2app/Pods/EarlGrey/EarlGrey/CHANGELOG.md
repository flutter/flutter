# Change Log

Details changes in each release of EarlGrey. EarlGrey follows [semantic versioning](http://semver.org/).

## [1.15.0](https://github.com/google/EarlGrey/tree/1.15.0) (08/03/2018)
```
Baseline: [59ce3b6c]
+ [59ce3b6c]: Fix default Swift version in EarlGreyExampleSwiftTests xcode project
```

### Enhancements
* Added support for accessibility in iOS 12.
* Updated the visibility checker to support keyboards in iOS 12.
* Updated Analytics Configurations.
* Fixed Formatting Issues.
* Updated invalid api and compatibility docs.

### Compatibility
* EarlGrey has now been tested for working till Xcode version 10.0 beta 2.
* Some of the internal unit tests break on Xcode 9.3+ due to change in exception name thrown by XCTest. Those are still being investigated.

## [1.14.0](https://github.com/google/EarlGrey/tree/1.14.0) (06/04/2018)
```
Baseline: [c201f58]
+ [c201f58]: Fix default Swift version in EarlGreyExampleSwiftTests xcode project
```

### Enhancements
* Add Swift 4 support in the gem.
* Update block declarations to support strict prototypes.
* Add support for PDF display for `UIWebViewIdlingResource`.
* Remove Swift 2 in the gem since Xcode 7.x is not supported anymore.

### Bug Fixes
* Fix `FTRLocalUIWebViewTest` by updating `testAJAXLoad` to detect proper web view elements.

### Compatibility
* EarlGrey has now been tested for working till Xcode version 9.4. Any small test breakages with Xcode 9.4 are being tested.

### Contributors
Thanks to [adam-b](https://github.com/adam-b) and [keefertaylor](https://github.com/keefertaylor)!

## [1.13.0](https://github.com/google/EarlGrey/tree/1.13.0) (04/03/2018)
```
Baseline: [2b3939a]
+ [2b3939a]: Fix Swift file issues with the updated EarlGrey code for release 1.13.0.
```

### Enhancements
* Add nullability to EarlGrey Headers. [Issue #449](https://github.com/google/EarlGrey/issues/449)
* Remove `notNil` method and add explicit check in the matcher itself.
* Update the Swift wrapper to use refined methods to prevent discardable result warnings.
* Update EarlGrey assert(with:) calls to assert(_:).
* Move the GREYRunLoopSpinner to spin on the thread passed to it instead of the main thread.
* Add tests for disabled buttons, fix visibility test and add iOS 11 support to tests.
* Move `EarlGreyImpl` interface out of EarlGrey.h.
* Add shake motion support to EarlGrey.

### Bug Fixes
* Use `TIPreferencesController` to change the keyboard settings so it will not load `TIUserWordsManager`, which can cause occasional crashes on iOS 11.0+.
* Tell the preferences not to show keyboard tutorial as it interferes with typing.
* Close MVC unconditionally to prevent erroneous scenarios where it fails to execute the completion block, leaving it resident on the screen forever.

### Compatibility
* EarlGrey has now been tested for working till Xcode version 9.3. Any small test breakages with Xcode 9.3 are being tested.

## [1.12.1](https://github.com/google/EarlGrey/tree/1.12.1) (09/01/2017)
```
Baseline: [405008e]
+ [405008e]: Release 1.12.1 to fix incorrect podspec release in 1.12.0.
```

### Bug Fixes
* Correct podspec to point to the version 1.12.1

## [1.12.0](https://github.com/google/EarlGrey/tree/1.12.0) (08/22/2017)
```
Baseline: [ae61a45]
+ [ae61a45]: Fix Main thread violation: UIView setHidden called from non-main thread.
```

### Enhancements
* More robust synchronization with `NSURLSession`. This fixes many flakiness seen with EarlGrey not waiting for the completion of callback methods after network response has been received.
* Performance improvements in GREYAppStateTracker. It uses a deallocation tracker in place of NSString to free up memory sooner.
* Fallback to `EarlGrey.swift` v3 when gem cannot find the correct file for the current swift version.
* Added `-Wdocumentation` for all EarlGrey projects.
* Use static constructor in place of initialize method for one-time setup.
* Remove extra parentheses added around failed assertion expressions.
* Updated error messages on failure of layout contraints.
* Improved Visibility checker's shifted pixel image redraw logic.

### Bug Fixes
* Fixed floating point issue in layout constraint matchers. [Issue #594](https://github.com/google/EarlGrey/issues/594)
* Fixed an issue where an exception is thrown when `-[UIWebDocumentView text]` is called in the middle of loading.
* Fixed a bug in `isKeyboardShown` with zero sized input accessory views.
* Fixed `CGAffineTransformInvert: singular matrix` message that appears during Pinch tests.

### Compatibility
* EarlGrey now supports Xcode version 9.0 up to 9.0 beta 6. All EarlGrey project tests pass with these versions.

## [1.11.0](https://github.com/google/EarlGrey/tree/1.11.0) (07/21/2017)

```
Baseline: [0d1086d]
+ [0d1086d]: Modify 1.10.2 -> 1.11.0 and update the CHANGELOG
```

### Enhancements
* Added support for iOS 11 & Xcode 9.0.
* Added the `grey_textFieldValue()` matcher for updates to UITextFields with iOS11.

### Bug Fixes
* Fixed Minor issue that was causing infinitely long touch paths for zero sized areas.
* Grammatical and Language Fixes.
* Refactored FunctionalTests tests for adding iOS 11 support.

## [1.10.1](https://github.com/google/EarlGrey/tree/1.10.1) (07/14/2017)

```
Baseline: [2abda72]
+ [2abda72]: Modified GREYElementInteraction.m to drain the thread for a timeout.
```

### Enhancements
* Improved `GREYAssert` macros to not wait until idle as it can cause it to never return.
* Improved Search action to not wait until idle as it can cause it to never return.

## [1.10.0](https://github.com/google/EarlGrey/tree/1.10.0) (07/05/2017)

```
Baseline: [a386cb2]
+ [a386cb2]: Update Changelog for the 1.10.0 release for the Screenshot Docs change.
```

### Bug Fixes
* Resolved visibility checker overlapping view issue. [Issue #532](https://github.com/google/EarlGrey/issues/532)
* Use accessibility ID in place of accessibility label for keyboard modifier keys. [Issue #539](https://github.com/google/EarlGrey/issues/539)

### Enhancements
* Removed `kGREYConfigKeyScreenshotDirLocation` in favor of `kGREYConfigKeyArtifactsDirLocation`.
* Fixed all issues reported by Xcode's static analysis.
* Fixed long press test failures on travis.
* Improved interaction error logging by adding more information about failure to the out error parameter.
* Added more error details to timeout failures.
* Add explicit 1st and 2nd param to grey_allOf and grey_anyOf to prevent redundant uses.
* Update jazzy copyright year.

### Compatibility
* Adding xcode version to backwards compatibility doc.

## [1.9.4](https://github.com/google/EarlGrey/tree/1.9.4) (06/09/2017)

```
Baseline: [76a6d65]
+ [76a6d65]: Updated Hierarchy traversal to use common traversal logic with DFS/BF.
```

### Bug Fixes
* Fixed a bug in scroll action that can sometimes cause a tap at the end of scroll.

### New Features
* Added `kGREYConfigKeyArtifactsDirLocation` configuration key for setting a custom folder to store artifacts.

### Enhancements
* Improved CI execution on travis.
* Updated test app with better AutoLayout support.
* Improved docs for earlgrey gem, contributors guide, etc.
* Fixed all asserts to use internal implementation instead of NSAssert which
  can be disabled.
* Updated cheatsheet render script to use Chrome 59.
* Consolidated DFS and BFS hierarchy traversals.
* Renamed `GREYExposed.h` to `GREYAppleInternals.h`
* Removed redundant categories and moved methods to private headers.

### Contributors
* [bootstraponline](https://github.com/bootstraponline)

## [1.9.3](https://github.com/google/EarlGrey/tree/1.9.3) (05/26/2017)

```
Baseline: [a3ba675]
+ [a3ba675]: Fix breaking test with Long Press
```

### Improvements
* Revaming of Swipe Touch Path Gestures to make them more like a real-user.

### Bug Fixes
* Fixed breaking tests for Long Press Gestures.
* Fix source_tree and relative path for the EarlGrey gem to prevent Carthage breakages.

## [1.9.2](https://github.com/google/EarlGrey/tree/1.9.2) (04/21/2017)

```
Baseline: [b9d7a7c]
   + [b9d7a7c]: Update OS=10.3 for travis CI
```

### Bug Fixes
* Fixed timeout related failures from being reported as assertion failures.
* Fixed to wait for rotation to complete before verifying that it changed.
* Fixed Swift breaks by correcting issue with Gem adding EarlGrey.swift for
  Objective C targets.
* Fixed race condition with reading and writing to state tracker elementID.

## [1.9.1](https://github.com/google/EarlGrey/tree/1.9.1) (04/14/2017)

```
Baseline: [932c3f6]
   + [932c3f6]: Doc updates
```

### Bug Fixes
* Fixed a bug in interaction point calculation for cases where activation point
and the center of visible area is hidden.

### Enhancements
* Updated documentation for GREYCondition and ruby setup.
* Minor improvements to formatting of failure messages.
* Updated travis to run tests on iOS 10.3 and Xcode 8.3.
* Deleted .arcconfig file.

### Contributors
* [bootstraponline](https://github.com/bootstraponline)

## [1.9.0](https://github.com/google/EarlGrey/tree/1.9.0) (03/31/2017)

```
Baseline: [6bceffc]
   + [6bceffc]: Sync 1.9.0
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.3 and iOS 10.3 on devices and simulators.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### New Features
* Add `-[GREYKeyboard dismissKeyboardWithError:]` API to dismiss the keyboard.

### Enhancements
* Improved earlgrey gem by removing post_install and letting pod update
  the project.
* Improved swift support for `grey_allOf` and `grey_anyOf`.
* Several documentation updates including installation steps improvements.
* Added gem badge to `README.md`.

### Contributors
* [bootstraponline](https://github.com/bootstraponline)
* [Felix Krause](https://github.com/KrauseFx)<br/>

## [1.8.0](https://github.com/google/EarlGrey/tree/1.8.0) (03/17/2017)

```
Baseline: [0dc7c18]
   + [0dc7c18]: 1.8.0 Release
```

### New Features
* Added multi-finger swipe action API's:
    * grey_multiFingerSwipeFastInDirection
    * grey_multiFingerSwipeSlowInDirection
    * grey_multiFingerSwipeFastInDirectionWithStartPoint
    * grey_multiFingerSwipeSlowInDirectionWithStartPoint

### Bug Fixes
* Fixed issue with accessibility spamming "Remote service does not respond to _accessibilityMachPort" message on iOS 9.1 device.
* Fixed issues with EarlGrey working with a `UIAccessibilityTextFieldElement`.
* Fixed typing by blacklisting `UICompatibilityInputViewController` in UIViewController tracking.

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.3 beta 4 and iOS 10.3 on devices and simulators.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### Enhancements
* Improvements to the EarlGrey FunctionalTests TestRig.
* All `GREYAssertXXX` macros now wait for the app to idle before being evaluated.
* Unified the `Copy Files` modification script for Carthage and CocoaPods support.

### Contributors
[bootstraponline](https://github.com/bootstraponline)<br/>
[petaren](https://github.com/petaren)

## [1.7.2](https://github.com/google/EarlGrey/tree/1.7.2) (02/17/2017)

```
Baseline: [6d55af5]
   + [6d55af5]: 1.7.2 Release
```

### Bug Fixes
* Fixed Swizzler to properly reset swizzled selectors.
* Fixed typing by blacklisting UICompatibilityInputViewController in UIViewController tracking.

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.2.1 and iOS 10.2.1 on devices and simulators.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### Enhancements
* Updated analytics to use an client ID instead of user ID.

### Contributors
[mbaxley](https://github.com/mbaxley), thank you!

## [1.7.1](https://github.com/google/EarlGrey/tree/1.7.1) (02/03/2017)

```
Baseline: [e026773]
+ [e026773]: Change version numbers for EarlGrey 1.7.1
```

### Bug Fixes
* Fixed an issue with constraint failure details not being logged in the error trace.
* Updated nullability for GREYMatchers to improve Swift support.
* Minor changes to logging strings and docs.

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.2.1 and iOS 10.2.1 on devices and simulators.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### Enhancements
* Updated analytics to use an md5 hashed uid.

## [1.7.0](https://github.com/google/EarlGrey/tree/1.7.0) (01/25/2017)

```
Baseline: [f823ff2]
+ [f823ff2]: Removing JSON escape in reported errors.
```

### Bug Fixes
* Fixed a flake in testTrackingZombieQueue.
* Fixed CGRectIntegralInside to handle negative rectangles.
* Improved memory handling by moving autorelease pool inside loops.
* Fixed the bundle id to be consistent across all the test projects.
* Minor CI and other bug fixes.

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.2.1 and iOS 10.2.1 on devices and simulators.

### New Features
* Updated analytics to include *hash* of test class name and *hash* of test case names to better estimate the volume of EarlGrey usage.
* Updated the readme to explain these changes.
* Updated tests for analytics to test new features.

### Enhancements
* Improved EarlGrey error logging for better post processing [Issue #392](https://github.com/google/EarlGrey/issues/392).
* Removed the deprecated methods and cleaned up private headers.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### Deprecations
* Removed deprecated methods `grey_pinchFastInDirection` and `grey_pinchSlowInDirection` in favor of `grey_pinchFastInDirectionAndAngle` and `grey_pinchSlowInDirectionAndAngle` respectively.

### Contributors
[bootstraponline](https://github.com/bootstraponline), [stkhapugin](https://github.com/stkhapugin) and [kebernet](https://github.com/kebernet)

## [1.6.2](https://github.com/google/EarlGrey/tree/1.6.2) (01/06/2017)

```
Baseline: [0cdda9c]
+ [0cdda9c]: EarlGrey Sync for 1.6.2
```

### Bug Fixes
* Updated the EarlGrey API for Swift 3.0 as per the latest guidelines.
* Improved web tests to work with current google.com UI.
* Fixed a bug in the visibility checker for 32bit platform.
* Fixed flakiness caused by NSDate issues in EarlGreyExampleSwiftTests.

### Enhancements
* Added a travis hook to stop CI runs for docs-only changes.

### Contributors
Thanks to [bootstraponline](https://github.com/bootstraponline)
and the rest of the contributors!

## [1.6.1](https://github.com/google/EarlGrey/tree/1.6.1) (12/20/2016)

```
Baseline: [9e04024]
   + [9e04024]: Release 1.6.1
```

### Bug Fixes
* Add a test for long pressing the link in the UI webview.
* Fix issue with xcodeproj gem in travis runs.

### Enhancements
* Update travis run to use Xcode 8.2

## [1.6.0](https://github.com/google/EarlGrey/tree/1.6.0) (12/06/2016)

```
Baseline: [5080a21]
   + [5080a21]: Updated changelog info.plist pod spec and gem version for 1.6.0 release.
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.
* Has been tested for support till iOS 10.1 on devices and simulator.

### Bug Fixes
* Fixed CocoaPods issue with using EarlGrey as a module in Swift projects.
* Fixed issue with Accessibility service not enabled for simulators and devices.
* Minor documentation and syntax fixes.

### Enhancements
* Moved failure handler from a global variable to a thread local storage, like NSAssertionHandlers.
* Exposed the angle for pinch action in GREYPinchAction.
* Added EarlGreyExample CocoaPods project to travis.

### Deprecations
* Deprecated `grey_pinchSlowInDirection` and `grey_pinchFastInDirection` in favor of
  `grey_pinchFastInDirectionAndAngle` and `grey_pinchSlowInDirectionAndAngle`.

## [1.5.3](https://github.com/google/EarlGrey/tree/1.5.3) (11/14/2016)

```
Baseline: [690eaa2]
   + [690eaa2]: Updated ChangeLog and pod spec for 1.5.3 release
```

### Enhancements
* Resolve CocoaPods rating [Github issue](https://github.com/CocoaPods/CocoaPods/issues/6175)

## [1.5.2](https://github.com/google/EarlGrey/tree/1.5.2) (11/11/2016)

```
Baseline: [f3ee931]
   + [f3ee931]: Updated ChangeLog and pod spec for 1.5.2 release
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.
* Has been tested for support till iOS 10.1 on devices and simulator.

### Enhancements
* Enhance precision of timer used for touch injection
* Removed requirement for bridging header for Swift and EarlGrey

## [1.5.1](https://github.com/google/EarlGrey/tree/1.5.1) (11/07/2016)

```
Baseline: [d9eb1bc]
   + [d9eb1bc]: Updated ChangeLog and pod spec for 1.5.1 release
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Bug Fixes
* Fixed CI Ruby test for Carthage.

### Enhancements
* Improved touch injection speed by making it work independent of the screen refresh rate.
* Added synchronization for `NSURLConnection::sendSynchronousRequest`.
* Exclude URLs that start with `data` scheme from being synchronized.
* Updated `grey_clearText` action to accept elements conforming to UITextInput protocol.

## [1.5.0](https://github.com/google/EarlGrey/tree/1.5.0) (10/31/2016)

```
Baseline: [55d42a4]
   + [55d42a4]: Updated ChangeLog and pod spec for 1.5 release
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for [Swift 3.0](https://docs.google.com/document/d/1AeleXccp35EUX4ILa6CT3CwlxLSZq1YLrco9JF27p9k/edit) and Swift 2.3.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Bug Fixes
* Failing analytics tests fixes.
* Fixed flaky Travis Stopwatch Test.
* Fixed rspec tests broken by ruby update and changing the directory.

### Enhancements
* Improved UIAppStateTracker APIs to allow for ignoring states.
* Improved failure handlers for multiple invocations within context of a valid test case.

### Deprecations
* Swift 2.2 is no longer supported.

## [1.4.0](https://github.com/google/EarlGrey/tree/1.4.0) (10/07/2016)

```
Baseline: [b5e34db]
   + [b5e34db]: Update Info.plist / Podspec / Cheatsheet for EarlGrey 1.4.0
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* EarlGrey.gem runs out of the box for Swift 2.2.x. For Swift 3.0, please
  use the [Swift Migration Guide](https://swift.org/migration-guide/) to
  add the `Use Legacy Swift` build setting to your test target until we
  provide support.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Enhancements
* A better way to blacklist URL's in GREYConfiguration by adding them to an NSArray.
* A verbose logger to provide more descriptive EarlGrey logs that can be enabled by
  setting the `kGREYAllowVerboseLogging` key in NSUserDefaults to `YES`. Verbose
  logging also measures the performance of interactions and the thread executor by
  using a stopwatch class.
* Improvements to `-[XCTestCase greyStatus]` to better reflect the status of a test.

### Bug Fixes
* Corrected selection of `UIPickerView`s even when they were disabled.
* Minor documentation and syntax fixes.

### Deprecations
* Deprecated `GREYFail` in favor of `GREYFailWithDetails`.

## [1.3.1](https://github.com/google/EarlGrey/tree/1.3.1) (09/19/2016)

```
Baseline: [c4913b]
   + [c4913b]: Update compatibility doc to include iOS 10.
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Enhancements
* Add autolayout to `FTRTypingViewController`

### Bug Fixes
* Minor documentation and syntax fixes.
* Fixed Functional Test Project scheme preventing it to be run on devices.
* Add a temporary hold on the xcodeproj gem dependency to unblock tests.

## [1.3.0](https://github.com/google/EarlGrey/tree/1.3.0) (09/09/2016)

```
Baseline: [6b2f329]
   + [6b2f329]: Add fixes for documentation.
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Has been tested for support till iOS 10 beta 4.

### New Features

* The following new matchers were added EarlGrey:
  * `grey_selected`: Checks if a UIControl is selected.
  * `grey_accessibilityFocused`: Checks if a UI element is focused by accessibility technologies
  like Voiceover or Switch Control.

### Enhancements
* Added an API to find the `XCTestCase` status through an EarlGrey test run.
* Improved the failure description in the failure handler.
* Made the `EarlGrey.swift` file syntax swiftier.
* Improved Unit and Functional test coverage.

### Bug Fixes
* Fixed Travis issue with the Ruby version.
* Minor documentation and syntax fixes.

### Deprecations
* `grey_elementAtIndex` has been removed in favor of the `atIndex:` interaction API. For migrating
  your tests, please follow the announcement
  [here](https://groups.google.com/forum/#!topic/earlgrey-discuss/Q6RhxRhtRvo).

### Contributors
Special thanks to [axi0mX](https://github.com/axi0mX),
[bootstraponline](https://github.com/bootstraponline),
[KazuCocoa](https://github.com/KazuCocoa) and the rest of our contributors.

## [1.2.0](https://github.com/google/EarlGrey/tree/1.2.0) (08/31/2016)

```
Baseline: [7070e1a]
   + [7070e1a]: Updated cheatsheet and podspec for 1.2.0 release
```

### New Features

* EarlGrey now supports multi-touch gestures! Following pinch actions have been added:
  * `grey_pinchFastInDirection`
  * `grey_pinchSlowInDirection`
* Added `atIndex:` interaction API to select from multiple element matches.

### Enhancements
* Updated Swift Macros in EarlGrey gem.
* Implemented matcher for UIScrollView scrolled to content edge.

### Bug Fixes
* Fixed several typos and cleaned up many project files with proper error messages.
* Added carthage `xcodebuild` command to Travis CI.
* Fixed issue with action{Did,Will}PerformAction notification and its userInfo.
* Updated protocol signatures.

### Contributors
Special thanks to [axi0mX](https://github.com/axi0mX) and the rest of our contributors.

## [1.1.0](https://github.com/google/EarlGrey/tree/1.1.0) (08/18/2016)

```
Baseline: [107dba5]
   + [107dba5]: Update podspec for 1.1.0 release [ci skip]
```

### New Features

* API reference documentation generated via [Jazzy](https://rubygems.org/gems/jazzy/)
* Cheatsheet for EarlGrey
* Carthage support
* Easier CocoaPods setup using [EarlGrey gem](https://rubygems.org/gems/earlgrey)
which replaces manually copying over `configure_earlgrey_pods.rb` and `EarlGrey.swift` file.

### Enhancements

* For demonstration purposes added Swift demo app and tests
* Update documentation for Swift usage
* Update contribution guidelines
* Added `grey_allOfMatchers` and `grey_anyOfMatchers` to EarlGrey.swift
* Use XCTest's mechanism of halting test execution instead of throwing arbitrary exception
* Helper method to speed up animation
* Added `grey_replaceText` action to directly replace text (without using keyboard) on a field
* Created `grey_atIndex` matcher for matching a single element from a list of matched elements
* Updated FAQs with questions and examples
* Update install guide with Cocoapods 0.39 support
* Added Badge for License, Cocoapod, and Travis
* Efficiency improvement in `GREYAppStateTracker` reducing O(n) to constant amortized time
* Improved webview synchronization
* Added tracking for `dispatch_async_f` and `dispatch_sync_f` methods
* Reduce throttling of CPU by allowing runloops to sleep when idle
* Removed unnecessary runloop drains improving overall speed and reliability
* Introduced trackers for `NSManagedObjectContext`
* Signal handlers and uncaught exception handler invoke previously installed handlers
* Improved accessibility logic to support beta versions of iOS 10

### Bug Fixes

* Race conditions in `GREYOperationQueueIdlingResourceTest`
* Race conditions in `GREYDispatchQueueIdlingResourceTest`
* Addressed Swift 3 related warnings in `EarlGrey.swift`
* Resigning first responder for autocorrect-enabled fields causes keyboard track to mistrack
keyboard disappearance events
* EarlGrey.xcodeproj fails to build for device because code signing identities aren't set
correctly
* Assertion failure in `-[GREYElementProvider dataEnumerator]` due to nil accessibility element
* Rubocop warnings in configure_earlgrey_pods.rb script and Podfile
* EarlGreyFunctionalTests `testSwipeOnWindow` always fails on iPhone 4S
* If parent directory has spaces, `setup-earlgrey.sh` will fail and exit
* Retain cycle in `GREYElementInteraction`
* Retain cycle in `UIApplication` mock in test suite
* Changed CFBundlePackageType in EarlGrey-Info.plist to FMWK

### Contributors
Special thanks to [bootstraponline](https://github.com/bootstraponline),
[axi0mX](https://github.com/axi0mX), and the rest of our contributors.

## [1.0.0](https://github.com/google/EarlGrey/tree/1.0.0) (02/16/2016)

First cup of EarlGrey.

```
Baseline: [7099484]
   + [7099484]: First version of EarlGrey.
```

Initial release.
