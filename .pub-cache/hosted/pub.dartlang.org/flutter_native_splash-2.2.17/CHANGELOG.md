## [2.2.17] - (2023-Jan-15)
- Updated image dependency to v4.0.10.  Fixes [#497](https://github.com/jonbhanson/flutter_native_splash/issues/497).
- Changed image processing from linear to cubic to improve image quality.  Fixes [#472](https://github.com/jonbhanson/flutter_native_splash/issues/472).

## [2.2.16] - (2022-Nov-27)

- Update documentation on Android 12.
- Fix web background image.  Thanks [Severin](https://github.com/Bungeefan) for [PR #459](https://github.com/jonbhanson/flutter_native_splash/pull/459).
- Support more image formats.  Thanks [Severin](https://github.com/Bungeefan) for [PR #460](https://github.com/jonbhanson/flutter_native_splash/pull/460).

## [2.2.15] - (2022-Nov-20)

- Fix iOS background image build incorrectly when background dark image is used.  Fixes [#452](https://github.com/jonbhanson/flutter_native_splash/issues/452), fixes [#439](https://github.com/jonbhanson/flutter_native_splash/issues/439).
- Correct background image/color handling on web.  Fixes [#450](https://github.com/jonbhanson/flutter_native_splash/issues/450), fixes [324](https://github.com/jonbhanson/flutter_native_splash/issues/324).
- Don't include dark styling in web if not specified in config.  Fixes [#453](https://github.com/jonbhanson/flutter_native_splash/issues/453).
- Add _Parameters class to hold parameters.

## [2.2.14] - (2022-Nov-07)

- Don't update `values-31` if there is no `android_12` section in the config.  Closes [#447](https://github.com/jonbhanson/flutter_native_splash/issues/447).
- Additional fix for index.html getting extra blank lines. Fixes [#430](https://github.com/jonbhanson/flutter_native_splash/issues/430).

## [2.2.13] - (2022-Oct-30)

- Corrected Android 12 dark parameters not defaulting to light parameters.  Thanks [elliotrtd](https://github.com/elliotrtd) for the [heads up](https://github.com/jonbhanson/flutter_native_splash/issues/400#issuecomment-1235100173) on this issue.

## [2.2.12] - (2022-Oct-23)

- Updated readme and dependancies.
- Add CI, resolve some lints, and fix tests.  Thanks [lsaudon](https://github.com/lsaudon) for [PR #433](https://github.com/jonbhanson/flutter_native_splash/pull/433).

## [2.2.11] - (2022-Oct-09)

- Fixed Android 11 color issue.  Fixes [#429](https://github.com/jonbhanson/flutter_native_splash/issues/429).
- Fix index.html getting extra blank lines.  Fixes [#430](https://github.com/jonbhanson/flutter_native_splash/issues/430).
- Update the readme.  Closes [#431](https://github.com/jonbhanson/flutter_native_splash/issues/431).

## [2.2.10+1] - (2022-Sep-25)

- Update bug report template.
- Package housekeeping to stay up to date with Flutter.

## [2.2.9] - (2022-Sep-07)

- Update pub.dev links.  Thanks [Joachim](https://github.com/nohli) for [PR #415](https://github.com/jonbhanson/flutter_native_splash/pull/415).
- Fix Android 12 branding issue.  Thanks [Matías](https://github.com/mirland) for [PR #414](https://github.com/jonbhanson/flutter_native_splash/pull/414).
- Corrected copyright notice.  Closes [#416](https://github.com/jonbhanson/flutter_native_splash/issues/416).
- Added Android 12 example.  Closes [#412](https://github.com/jonbhanson/flutter_native_splash/issues/412).

## [2.2.8] - (2022-Aug-21)

- Use Theme.Light.NoTitleBar.  Fixes [#402](https://github.com/jonbhanson/flutter_native_splash/issues/402).
- Correct android spelling in readme.  Thanks [Muhammad](https://github.com/itsahmed-dev) for [PR #407](https://github.com/jonbhanson/flutter_native_splash/pull/407).
- Use html parser.  Thanks [OutdatedGuy](https://github.com/OutdatedGuy) for [PR #396](https://github.com/jonbhanson/flutter_native_splash/pull/396).
- Separate branding property for Android 12.  Closes [#405](https://github.com/jonbhanson/flutter_native_splash/issues/405).

## [2.2.7] - (2022-July-31)

- Remove branding on Android 12 if branding is not specified.  Fixes [#399](https://github.com/jonbhanson/flutter_native_splash/issues/399).

## [2.2.6] - (2022-July-24)

- Fix parseColor test.  Thanks [mihiro](https://github.com/mihiron) for [PR #393](https://github.com/jonbhanson/flutter_native_splash/pull/393).
- Fix branding image source link broken and optimized code with optional chaining operator.  Thanks [OutdatedGuy](https://github.com/OutdatedGuy) for [PR #394](https://github.com/jonbhanson/flutter_native_splash/pull/394) and [PR #395](https://github.com/jonbhanson/flutter_native_splash/pull/395).

## [2.2.5] - (2022-July-17)

- Added Branding Image support for the web platform.  Thanks [OutdatedGuy](https://github.com/OutdatedGuy) for [PR #386](https://github.com/jonbhanson/flutter_native_splash/pull/386).
- Fix android12 config name.  Thanks [mihiro](https://github.com/mihiron) for [PR #390](https://github.com/jonbhanson/flutter_native_splash/pull/390).

## [2.2.4] - (2022-July-03)

- Added parameters for platform-specific images. Closes [#375](https://github.com/jonbhanson/flutter_native_splash/issues/375).
- Remove black status bar which appeared on Android devices with a notch. Fixes [#311](https://github.com/jonbhanson/flutter_native_splash/issues/311).

## [2.2.3+1] - (2022-June-12)

- Updated readme.

## [2.2.3] - (2022-June-5)

- Create new storyboard file rather than try to modify existing file. Closes [#369](https://github.com/jonbhanson/flutter_native_splash/issues/369).
- Reverted 2.1.6 change of using light settings for dark mode if omitted. Fixes [#368](https://github.com/jonbhanson/flutter_native_splash/issues/368).

## [2.2.2] - (2022-May-29)

- Corrected Android 12 color overriding color parameter. Closes [#365](https://github.com/jonbhanson/flutter_native_splash/issues/365).
- Add support for setting screen orientation in Android. Closes [#344](https://github.com/jonbhanson/flutter_native_splash/issues/344).

## [2.2.1] - (2022-May-22)

- Updated dependencies. Closes [#358](https://github.com/jonbhanson/flutter_native_splash/issues/358).
- Added Android 12 background color support. Closes [#357](https://github.com/jonbhanson/flutter_native_splash/issues/357).
- Resolve exception that occurs when using remove command. Closes [#355](https://github.com/jonbhanson/flutter_native_splash/issues/355).

## [2.2.0+1] - (2022-May-15)

- Added flavor support. Thanks [Vladimir](https://github.com/vlazdra) for PR [#316](https://github.com/jonbhanson/flutter_native_splash/pull/316)! Closes [#160](https://github.com/jonbhanson/flutter_native_splash/issues/160).
- Fix androidV31StylesXml not being generated when darkBackgroundImage is set. Thanks (Hallot)[https://github.com/Hallot] for PR [#349](https://github.com/jonbhanson/flutter_native_splash/pull/349).
- Fix incorrect android_12 check for image_dark. Closes [#347](https://github.com/jonbhanson/flutter_native_splash/issues/347).
- Fix Flutter v3 WidgetsBinding.Instance! Null check warning. Closes [#351](https://github.com/jonbhanson/flutter_native_splash/issues/351).

## [2.1.6] - (2022-Apr-17)

- Use light settings for dark mode if dark mode settings are omitted.
- Add ALT tag for web. Fixes [#339](https://github.com/jonbhanson/flutter_native_splash/issues/339).

## [2.1.5] - (2022-Apr-10)

- Thanks [Yousef](https://github.com/YDA93) for [PR #332](https://github.com/jonbhanson/flutter_native_splash/pull/332) adding stricter lint rules and [zuboje](https://github.com/zuboje) for [PR #334](https://github.com/jonbhanson/flutter_native_splash/pull/334) adding deprecated message.

## [2.1.3+1] - (2022-Apr-03)

- Updated documentation. Closes [#327](https://github.com/jonbhanson/flutter_native_splash/issues/327).
- `remove` correctly handles multiple plist files. Fixes [#247](https://github.com/jonbhanson/flutter_native_splash/issues/247).

## [2.1.2+1] - (2022-Mar-27)

- Add branding support in Android 12. Thanks [Vladimir](https://github.com/vlazdra) for the [PR](https://github.com/jonbhanson/flutter_native_splash/pull/316).
- Updated readme. Closes [#317](https://github.com/jonbhanson/flutter_native_splash/issues/317). Closes [#318](https://github.com/jonbhanson/flutter_native_splash/issues/318).
- Don't create a blank branding image set. Fixes [#264](https://github.com/jonbhanson/flutter_native_splash/issues/264).

## [2.1.1] - (2022-Mar-13)

- Fix for pixelated splash image on web. Fixes [#263](https://github.com/jonbhanson/flutter_native_splash/issues/263).

## [2.1.0] - (2022-Mar-06)

- Expanded options for Android 12. Thanks [Jose](https://github.com/JCQuintas) for the [PR](https://github.com/jonbhanson/flutter_native_splash/pull/300) that served as a good starting point.

## [2.0.5] - (2022-Feb-20)

- Converted to a plugin since there is now platform specific code.

## [2.0.4] - (2022-Feb-15)

- Fix Error: Not found: 'dart:js' error. Fixes [#292](https://github.com/jonbhanson/flutter_native_splash/issues/292).

## [2.0.3+1] - (2022-Feb-14)

- Added preserve() and remove() methods.
- Remove splash from DOM in web.

## [2.0.2] - (2022-Feb-07)

- Update existing styles xml to support Xiaomi/Redmi devices. Fixes [#285](https://github.com/jonbhanson/flutter_native_splash/issues/285), fixes [#281](https://github.com/jonbhanson/flutter_native_splash/issues/281).
- Avoid changing logo size on mobile browsers. Fixes [#276](https://github.com/jonbhanson/flutter_native_splash/issues/276).

## [2.0.1+1] - (2022-Jan-29)

- Provide BuildContext argument to the initialization function.

## [2.0.0] - (2022-Jan-29)

- BREAKING CHANGE: Added `removeAfter` method which allows the native splash to remain until an initialization routine is complete. In order to use this method, the `flutter_native_splash` dependency must be moved from `dev_dependencies` to `dependencies`. Thanks [Ahmed](https://github.com/Ahmed-gubara) for the tip. Closes [#271](https://github.com/jonbhanson/flutter_native_splash/issues/271).

## [1.3.3] - (2022-Jan-01)

- Merged PR that adds branding. Thanks [Faiizii](https://github.com/Faiizii) for PR. Closes [#256](https://github.com/jonbhanson/flutter_native_splash/issues/256).
- Updated readme. Closes [#258](https://github.com/jonbhanson/flutter_native_splash/issues/258).
- Fix so that the splash screen does not cover the app in web. Fixes [253](https://github.com/jonbhanson/flutter_native_splash/issues/253).
- Updates per linter rules.

## [1.3.2] - (2021-Nov-28)

- Updated readme. Hide splash image in web from screen readers. Closes [#231](https://github.com/jonbhanson/flutter_native_splash/issues/231).

## [1.3.1] - (2021-Oct-27)

- Don't create Android 12 night res files if dark mode is not configured. Fixes [#227](https://github.com/jonbhanson/flutter_native_splash/issues/227). `Remove` command takes dark mode into account.

## [1.3.0] - (2021-Oct-26)

- Added Android 12 support. Closes [#204](https://github.com/jonbhanson/flutter_native_splash/issues/204), closes [#226](https://github.com/jonbhanson/flutter_native_splash/issues/226).

## [1.2.4] - (2021-Sep-23)

- Updated readme. Thanks [@j-j-gajjar](https://github.com/j-j-gajjar) for PR [#216](https://github.com/jonbhanson/flutter_native_splash/pull/216).
- Remove references to background images in web when images are missing. Fixes [#196](https://github.com/jonbhanson/flutter_native_splash/issues/196).
- Updated dependencies.

## [1.2.3] - (2021-Sep-08)

- Reverted XML dependency to be compatible with stable Flutter branch. Closes [#206](https://github.com/jonbhanson/flutter_native_splash/issues/206).

## [1.2.2] - (2021-Sep-06)

- Added a FAQ to address the deprecation of `SplashScreenDrawable`. Closes [#199](https://github.com/jonbhanson/flutter_native_splash/issues/199).
- Added `<picture>` tag to `index.html` by finding the `</body>` tag instead of `src="main.dart.js`, which was removed in Flutter 2.5. Fixes [#202](https://github.com/jonbhanson/flutter_native_splash/issues/202).
- Added `<item name="android:forceDarkAllowed">false</item>` tag to dark mode `styles.xml` to improve Xiaomi support. Closes [#184](https://github.com/jonbhanson/flutter_native_splash/issues/184).

## [1.2.1] - (2021-Jul-19)

- Check the file type and exit with error if it is not a PNG.
- Updated documentation with more FAQs.
- Fixed bug that was preventing copying of images for web. Fixes [#192](https://github.com/jonbhanson/flutter_native_splash/issues/192).
- Changed the example to show a secondary splash screen.
- Check that android, web, and ios folders exist before updating respective splash screen.

## [1.2.0] - (2021-Jun-09)

- Added beta support for Android 12. Closes [#175](https://github.com/jonbhanson/flutter_native_splash/issues/175).

## [1.1.9] - (2021-Jun-09)

- Added path argument to command line. Thanks [@lyledean1](https://github.com/lyledean1) for PR [#180](https://github.com/jonbhanson/flutter_native_splash/pull/180).

## [1.1.8+4] - (2021-Apr-20)

- Fixed bug that was preventing copying of dark background. Fixes [#163](https://github.com/jonbhanson/flutter_native_splash/issues/163).

## [1.1.7+1] - (2021-Apr-02)

- flutter_native_splash:remove adheres to android/ios/web setting. Fixes [#159](https://github.com/jonbhanson/flutter_native_splash/issues/159).
- Updated readme images.

## [1.1.6+1] - (2021-Mar-29)

- Corrected Android scaling. Thanks [@chris-efission](https://github.com/chris-efission).
- Updated readme image.

## [1.1.5+1] - (2021-Mar-23)

- Added unit tests.
- Updated dependency.

## [1.1.4+1] - (2021-Mar-18)

- Fixed bug that created duplicate android:windowFullscreen tags in styles.xml. Closes [#147](https://github.com/jonbhanson/flutter_native_splash/issues/147).
- Fixed fullscreen in Android dark mode.
- Print errors instead of throwing exceptions for cleaner output.
- Added message for missing subviews in iOS LaunchScreen.storyboard. Fixes [#146](https://github.com/jonbhanson/flutter_native_splash/issues/146).
- Removed duplicate exceptions for missing image file since that is now checked at package start.

## [1.1.3] - (2021-Mar-18)

- Fixed bug that was giving error on copying background image. Closes [#144](https://github.com/jonbhanson/flutter_native_splash/issues/144).

## [1.1.2] - (2021-Mar-17)

- Check that image files exist before starting. Throw an exception if image file not found.

## [1.1.1+1] - (2021-Mar-16)

- Create Styles.css before writing to it. Closes [#141](https://github.com/jonbhanson/flutter_native_splash/issues/141)
- Make all file calls synchronously to make code cleaner.

## [1.1.0] - (2021-Mar-15)

- Added option for background image. Closes [#22](https://github.com/jonbhanson/flutter_native_splash/issues/22).

## [1.0.3] - (2021-Mar-05)

- Updated readme.

## [1.0.2] - (2021-Mar-04)

- Added exception for missing/renamed splash image in LaunchScreen.storyboard.

## [1.0.1+1] - (2021-Mar-02)

- Corrected location of `picture` tag in web to ensure that splash disappears. Thanks [Dawid Dziurla](https://github.com/dawidd6).

## [1.0.0] - (2021-Feb-19)

- Adds null safety. Closes [#127](https://github.com/jonbhanson/flutter_native_splash/issues/127).

## [0.3.0] - (2021-Feb-10)

- Added support for web. Closes [#30](https://github.com/jonbhanson/flutter_native_splash/issues/30).
- Updated the example app to include web.

## [0.2.11] - (2021-Feb-09)

- Fixed `remove` command which was leaving splash images in place.

## [0.2.10] - (2021-Feb-08)

- Replaced `android_fullscreen` with `fullscreen` parameter, adding iOS support. closes [#75](https://github.com/jonbhanson/flutter_native_splash/issues/75), closes [#65](https://github.com/jonbhanson/flutter_native_splash/issues/65).
- The package no longer modifies the AppDelegate. Fixes [#125](https://github.com/jonbhanson/flutter_native_splash/issues/125), fixes [#66](https://github.com/jonbhanson/flutter_native_splash/issues/66).
- Added `remove` command. Closes [#97](https://github.com/jonbhanson/flutter_native_splash/issues/97), closes [#126](https://github.com/jonbhanson/flutter_native_splash/issues/126).
- Updated docs.

## [0.2.9] - (2021-Jan-27)

- Correct iOS 2x scaling. Closes [#27](https://github.com/jonbhanson/flutter_native_splash/issues/27).
- Fullscreen defaults to false. Closes [#122](https://github.com/jonbhanson/flutter_native_splash/issues/122).

## [0.2.8] - (2021-Jan-25)

- Allow users to set Android gravity and iOS ContentMode directly.
- Parse LaunchScreen.storyboard with XML package for more reliability.
- Updated install instructions.
- Fixes [#18](https://github.com/jonbhanson/flutter_native_splash/issues/18). Closes [#63](https://github.com/jonbhanson/flutter_native_splash/pull/63).

## [0.2.7] - (2021-Jan-18)

- Added configuration parameter to specify the info.plist location(s).
- Updated documentation.
- Fixes [#120](https://github.com/jonbhanson/flutter_native_splash/issues/120), [#42](https://github.com/jonbhanson/flutter_native_splash/issues/42).

## [0.2.6] - (2021-Jan-14)

- Added support for Android -v21 resource folders, which appear in the Flutter beta channel.
- Parse launch_background.xml with XML package for more reliability.
- Fixes [#104](https://github.com/jonbhanson/flutter_native_splash/issues/104), [#118](https://github.com/jonbhanson/flutter_native_splash/issues/118).

## [0.2.5] - (2021-Jan-13)

- Handle color parameter that are passed as integers. Fixes [#103](https://github.com/jonbhanson/flutter_native_splash/issues/103)

## [0.2.4] - (2021-Jan-12)

- Update code that adds fullscreen mode to Android so that it selects the right style (LaunchTheme) in styles.xml. This should resolve [#39](https://github.com/jonbhanson/flutter_native_splash/issues/39), [#54](https://github.com/jonbhanson/flutter_native_splash/issues/54), [#67](https://github.com/jonbhanson/flutter_native_splash/issues/67), [#92](https://github.com/jonbhanson/flutter_native_splash/issues/92), [#112](https://github.com/jonbhanson/flutter_native_splash/issues/112), and [#117](https://github.com/jonbhanson/flutter_native_splash/issues/117).
- Removed code that modifies MainActivity as it is not longer needed since Flutter embedding V2 uses two styles in styles.xml so full screen is set independently in the style.

## [0.2.3] - (2021-Jan-11)

- Further modifications to raise [pub points](https://pub.dev/help/scoring): The
  public API's need to have dartdoc comments, so all public declarations that did not
  need to be public were changed to private. Added doc comments for public APIs.

## [0.2.2] - (2021-Jan-09)

- Corrected color of background PNG for iOS. ([The channel order of a uint32 encoded color is BGRA.](https://pub.dev/documentation/image/latest/image/Color/fromRgb.html)) ([#115](https://github.com/jonbhanson/flutter_native_splash/issues/115))

## [0.2.1] - (2021-Jan-08)

- Modifications to raise [pub points](https://pub.dev/help/scoring): Adherence to [Pedantic](https://pub.dev/packages/pedantic) code standard, and [conditional imports](https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files) to avoid losing points for lack of multiple platform support.

## [0.2.0+1] - (2021-Jan-08)

- Updated version number in README.md (thanks [@M123-dev](https://github.com/M123-dev))

## [0.2.0] - (2021-Jan-07)

- Added dark mode.

## [0.1.9] -

- (2020-Jan-27) Added createSplashByConfig for external usage
- (2020-Jan-05) Fix run the package command (thanks [@tenhobi](https://github.com/tenhobi))
- (2019-Oct-31) Removing comments from the example (thanks [@lucalves](https://github.com/lucalves))
- (2019-Oct-16) `image` parameter is now optional ([#26](https://github.com/jonbhanson/flutter_native_splash/issues/26))

## [0.1.8+4] - (12th October 2019)

- Fix bug on RegEx preventing `package` tag from being found in `AndroidManifest.xml` ([#25](https://github.com/jonbhanson/flutter_native_splash/issues/25))

## [0.1.8+3] - (4th October 2019)

- Prevent unhandled int exception in `color` argument (thanks [@wemersonrv](https://github.com/wemersonrv) - PR [#23](https://github.com/jonbhanson/flutter_native_splash/pull/23))

## [0.1.8+2] - (16th September 2019)

- Fix code being added multiple times to `MainActivity` ([#19](https://github.com/jonbhanson/flutter_native_splash/issues/19))

## [0.1.8+1] - (16th September 2019)

- Documentation improvements

## [0.1.8] - (16th September 2019)

- Added `fill` property to use full screen images on Android (thanks [@Bwofls2](https://github.com/Bwolfs2) - PR [#8](https://github.com/jonbhanson/flutter_native_splash/pull/8))
- Added `android_disable_fullscreen` property to disable opening app in full screen on Android ([#14](https://github.com/jonbhanson/flutter_native_splash/issues/14))
- Status bar color on Android is now generated dynamically by using same principles as Material Design (thanks [@yiss](https://github.com/yiss) - PR [#16](https://github.com/jonbhanson/flutter_native_splash/pull/16))

## [0.1.7+2] - (1th September 2019)

- Fix a bug on `minSdkVersion` reading ([#13](https://github.com/jonbhanson/flutter_native_splash/issues/13))

## [0.1.7+1] - (1th September 2019)

- Check for `minSdkVersion` >= 21 to add code for changing status bar color to transparent ([#12](https://github.com/jonbhanson/flutter_native_splash/issues/12))

## [0.1.7] - (27th August 2019)

- Fix a bug that duplicates entries on `Info.plist` when using multiple `</dict>` on iOS ([#5](https://github.com/jonbhanson/flutter_native_splash/issues/5))
- Fix missing imports on `MainActivity` when not using default class signature ([#7](https://github.com/jonbhanson/flutter_native_splash/issues/7))

## [0.1.6+2] - (27th August 2019)

- Yup, I released a new version because a quote was missing

## [0.1.6+1] - (27th August 2019)

- Updated README.md adding quotes on `color` property
- Add support for colors with `#` prefix

## [0.1.6] - (26th August 2019)

- Fix bug where `MainActivity` file could not be found with custom package names

## [0.1.5] - (26th August 2019)

- Add support for Kotlin
- Add support for Swift
- Add `await` to every step to create splash screen on Android and iOS to prevent async steps causing error

## [0.1.4] - (25th August 2019)

- Fix code style issues pointed by `dartanalzyer`
- Fix typo in README.md

## [0.1.3] - (25th August 2019)

- Update README.md

## [0.1.2] - (25th August 2019)

- Fix Travis CI filename

## [0.1.1] - (25th August 2019)

- Added Travis CI and updates to README.md

## [0.1.0] - (25th August 2019)

- Initial release: generate Android and iOS splash screens with a background color and an image
