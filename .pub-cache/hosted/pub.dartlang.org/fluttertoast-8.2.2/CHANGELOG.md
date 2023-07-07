## [8.2.2]

- Adjustments for flutter >=3.10

## [8.2.1]

- Removed `context.mounted`

## [8.2.0]

- Updated the flow for Toast with Context

## [8.1.4]

- Merged #419 (added environment restriction in pubspec)

## [8.1.3]

- Merged #415 (improvements to provide safer usage) @AlexSeednov
- Updated Readme.md

## [8.1.2]

- Merged #405 #408

## [8.1.1] [8.1.0]

- Many issues fixed
- iOS M1 Chip Fix

## [8.0.9]

- Merged PRS #342 #353 #363 #346 and #370

## [8.0.8]

- Many issues fixed

## [8.0.7]

- Added fadeDuration in FToast to set fade animation Duration
- Fixed Toast behind the screen #287 , #281
- Fixed #303
## [8.0.6]

- Only safe (?.) or non-null asserted (!!.) (#300)

## [8.0.5]

- Fixed Unresolved reference: R (Issue with Android API 30)
## [8.0.4]

- Fixed Unresolved reference: R (Issue with Android API 30)

## [8.0.3]

- flutter analyze fixes

## [8.0.2]

- Null Safety
- Code Docs Added

## [7.1.8]

- Web sourceMap Warning

## [7.1.7]

- '\n' line crash on Web PR Merged
- Android 11 Crash fixed
- Many bug fixes

## [7.1.6]

- minor fixes

## [7.1.4]

- minor fixes

## [7.1.3]

- Android Default bg when fontSize or textColor set fixed

## [7.1.2]

- Android Rounded Corners fix (#238)
- Android Crash if cancel called before init (#231)
- Web now load js & css from assets
- Web SyntaxError if Toast msg has `'` fixed

## [7.1.1]

- iOS Unused variables fix

## [7.1.0]

- Breaking change for FToast, Need to call `FToast.init(context)` before `showToast`
- AnimationController fix
- Android `NonNull` build Fix
- FToast Added new `PositionedToastBuilder` you can define Custom Postition now for toast
- Merged #228, Fix UIView+Toast.o duplicate symbols - Thanks @jackkang0401 and @yongshuai.kang
- Now `textcolor` will work for web toast

## [7.0.4]

- iOS Build Failed Fixed #218
- Fixed Cancel Toasts in iOS

## [7.0.3]

- FToast now Fade when showing and hiding the toast
- Toast backgroud now supports transparency
- Bug fixes

## [7.0.2]

- iOS Toast behind keyboard fixed. #203

## [7.0.1+1]

- Readme Updated

## [7.0.1]

- Android Build failed fix
- iOS Crash Fix

## [7.0.0]

- Reverted to Old code `Fluttertoast`
- Also contains new code `FToast`

## [6.0.1]

- Support for old `Fluttertoast.showToast`

## [6.0.0]

- Complete new package
- Now plugin dont use any native code

## [5.0.2]

- Web Fix after name change


## [5.0.1]

- Many things changes on android side (this will break your current implementation)
- `Fluttertoast.` to `FlutterToast.`
- many fixes

## [4.0.2]

- Delete print on fluttertoast_web

## [4.0.1]

- ReadMe Fixes

## [4.0.0]

- Added Web Support

## [3.1.3]

- Toast optimized for Android

## [3.1.2]

- Flutter analysis failed fixed

## [3.1.1]

- Not Compiling in android (issue with AndroidX)

## [3.1.0]

- Migrated to AndroidX

##[3.0.6]

- iOS build failed fixed

## [3.0.5]

- deprecation fixed
- hope ios notch fixed

## [3.0.4]

- Android Color fix

## [3.0.3]

- fixed Android Toast.LENGTH\_\*

## [3.0.2]

- fixed #70 #71

## [3.0.1]

- Release build failed fix
- Multiline text android fix

## [3.0.0]

- Migrated to AndroidX

## [2.2.12]

- Incomplete Text Fix

## [2.2.11]

- Incomplete Text Fix

## [2.2.10]

- iOS build Failed fix

## [2.2.9]

- iOS build Failed fix

## [2.2.8]

- `Fluttertoast.cancel()` added
- FlutterToast Implementation revert back to previous

## [2.2.7]

- FontSize Can be changed
- FlutterToast Implementation Changed to `FlutterToast.instance`

## [2.2.6]

- removed androidx

## [2.2.5]

- Cannot build because of dependency w/ v28 #47

## [2.2.4]

- androidX crash fix #45

## [2.2.3]

- iOS Crash fix #41 & #39

## [2.2.1]

- default toast style fix #38

## [2.2.0]

- Background color fixed #29

## [2.1.5]

- Merged PR #36 - Fix Number Cast Error for issue #35

## [2.1.4]

- Merged PR #32

## [2.1.2]

- iOS Color Fix
- Background color fix in PIE

## [2.1.1]

- Background color does not fill the whole Toast fixed

## [2.1.0]

- build error fixed

## [2.0.9]

- fix error in flutter 0.9.7

## [2.0.8]

- Build failed with an exception fixed
- The plugin calls the build of the previous widget fixed
- Screenshots added

## [2.0.7]

- Text background fix for android

## [2.0.6]

- iOS Release build error fixed

## [2.0.3]

- iOs run time error fixed

## [2.0.2]

- iOs build error fixed

## [2.0.1]

- Ios Support added
- option for setting toast gravity (top, center, bottom)

## [1.0.1]

- Initial Open Sources
- show Toast in Android
