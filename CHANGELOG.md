In general, our philosophy is to update the `stable` channel on a quarterly basis with feature updates. In the intervening period, occasionally we may decide a bug or regression warrants a hotfix. We tend to be extremely conservative with these hotfixes, since there's always a risk that fixing one bug introduces a new one, and we want the `stable` channel to always represent our most tested builds.

We intend to announce hotfixes to the [flutter-announce](https://groups.google.com/forum/#!forum/flutter-announce) group, and we recommend that you subscribe to that list if you publish an application using Flutter.

Note that we only hotfix the latest version -- if you see bugs on older versions of the `stable` channel, please consider moving to the latest `stable` channel version.

To ensure that you have the latest stable version with the hotfixes listed below, use the flutter tool at the command line as follows:

```
$ flutter channel stable
$ flutter upgrade
```

<!--
INTERNAL NOTE: DO **NOT** READ THIS FILE IN A TEST OR BUILDER.

As an optimization, `CHANGELOG.md`-only PRs skip almost all
tests, except `Linux analyze`. It is unsafe to read and use
this file in a test unless it is part of the Linux analyze
task (and that specific task, with that specific name).

INTERNAL NOTE: PLEASE DON'T JUST PASTE ISSUE TITLES!

Make sure that the text here helps customers understand
whether they are likely to be affected by the issue,
without them needing to read each issue individually.
Our goal is to make the list easy for them to scan.

More information and tips:
docs/releases/Hotfix-Documentation-Best-Practices.md
-->

## Flutter 3.38 Changes

### [3.38.0-0.2.pre](https://github.com/flutter/flutter/releases/tag/3.38.0-0.2.pre)

- [flutter/176462](https://github.com/flutter/flutter/issues/176462) Improves error message when building for iOS fails due to precompiled headers cache error.
- [flutter/176206](https://github.com/flutter/flutter/issues/176206) Adds MacOS warning that wireless debugging may be slow on iOS 26 that is forwarded to DAP clients, e.g. VSCode
- [flutter/177037](https://github.com/flutter/flutter/issues/177037) Allows some Android apps that use dynamic modules to build from Android Studio.
- [flutter/177320](https://github.com/flutter/flutter/issues/177320) Support most recently published Android AGP/KGP.Java/Gradle dependencies.
- [flutter/176310](https://github.com/flutter/flutter/issues/176310) For Flutter web applications run with `--machine`, ensure `app.dtd` event is emitted.
- [flutter/177401](https://github.com/flutter/flutter/pull/177401) Fixes a macOS text input crash caused by down-casting the string argument from Any to a NSString.
- [flutter/177308](https://github.com/flutter/flutter/pull/177308) Configures `FfiNative` resolver on dart:io.
- [flutter/176360](https://github.com/flutter/flutter/issues/176360) Fixes accessibility events regression on Linux which makes apps not announced with screen reader.
- [flutter/174791](https://github.com/flutter/flutter/issues/174791) Fixes Flutter web hot reload/restart crashes when the browser tab is closed, causing “Bad state: No element” errors and breaking the DWDS connection.
- [flutter/173770](https://github.com/flutter/flutter/issues/173770) Mitigates a memory leak that occurs on Android when Activities are not kept and an Activity is exited and re-entered.

### [3.38.0-0.1.pre](https://github.com/flutter/flutter/releases/tag/3.38.0-0.1.pre)

#### Framework
* Allow OverlayPortal.overlayChildLayoutBuilder to choose root Overlay by @chunhtai in https://github.com/flutter/flutter/pull/174239
* [Widget Preview] Add `group` property to `Preview` by @bkonyi in https://github.com/flutter/flutter/pull/174849
* Fix: Use route navigator for CupertinoSheetRoute pop by @rkishan516 in https://github.com/flutter/flutter/pull/173103
* fix(Semantics): Ensure semantics properties take priority over button's by @pedromassango in https://github.com/flutter/flutter/pull/174473
* Fix SliverMainAxisGroup scrollOffsetCorrection by @manu-sncf in https://github.com/flutter/flutter/pull/174369
* Depend on operator overload synthesis for three-way and equality comparisons. by @chinmaygarde in https://github.com/flutter/flutter/pull/174892
* Nav bar static components respect ambient MediaQueryData by @victorsanni in https://github.com/flutter/flutter/pull/174673
* Adjust default CupertinoCheckbox size on desktop by @victorsanni in https://github.com/flutter/flutter/pull/172502
* Update transformHitTests documentation for clarity by @Rushikeshbhavsar20 in https://github.com/flutter/flutter/pull/174286
* Add semanticIndexOffset argument to SliverList.builder, SliverGrid.builder, and SliverFixedExtentList.builder by @rodrigogmdias in https://github.com/flutter/flutter/pull/174856
* chore: move engine docs out of engine/ and into docs/ by @jtmcdole in https://github.com/flutter/flutter/pull/175195
* CupertinoContextMenu child respects available screen width by @victorsanni in https://github.com/flutter/flutter/pull/175300
* [a11y-app] Fix form field label and error message by @bleroux in https://github.com/flutter/flutter/pull/174831
* Engine Support for Dynamic View Resizing by @LouiseHsu in https://github.com/flutter/flutter/pull/173610
* [web] Unskip Cupertino datepicker golden tests in Skwasm by @harryterkelsen in https://github.com/flutter/flutter/pull/174666
* Add `CupertinoLinearActivityIndicator` by @ValentinVignal in https://github.com/flutter/flutter/pull/170108
* Fix RadioGroup single selection check. by @ksokolovskyi in https://github.com/flutter/flutter/pull/175654
* Fix: Update docs tool tag to sample in ImageProvider by @dixita0607 in https://github.com/flutter/flutter/pull/175256
* [Widget Preview] Allow for custom `Preview` annotations, add support for runtime transformations by @bkonyi in https://github.com/flutter/flutter/pull/175535
* [web] Cleanup opportunities post renderer unification by @mdebbar in https://github.com/flutter/flutter/pull/174659
* Load fonts in the order addFont is called by @jiahaog in https://github.com/flutter/flutter/pull/174253
* Fix outdated link of `intl` package to point to the correct new location  by @AbdeMohlbi in https://github.com/flutter/flutter/pull/174498
* Add non uniform TableBorder by @korca0220 in https://github.com/flutter/flutter/pull/175773
* fix: remove final class modifier on MenuController by @rkishan516 in https://github.com/flutter/flutter/pull/174490
* Add an assertion for the relationship between `Visibility.maintainState` and `Visibility.maintainFocusability` by @Renzo-Olivares in https://github.com/flutter/flutter/pull/175552
* fix: cupertino sheet broken example with programatic pop by @rkishan516 in https://github.com/flutter/flutter/pull/175709
* Fix SliverMainAxisGroup SliverEnsureSemantics support by @manu-sncf in https://github.com/flutter/flutter/pull/175671
* Cleans up navigator pop and remove logic by @chunhtai in https://github.com/flutter/flutter/pull/175612
* Fix docs in `EditableText` by @Renzo-Olivares in https://github.com/flutter/flutter/pull/175787
* Make sure that a CupertinoDesktopTextSelectionToolbarButton doesn't c… by @ahmedsameha1 in https://github.com/flutter/flutter/pull/173894
* Implement Regular Windows for the win32 framework + add an example application for regular windows by @mattkae in https://github.com/flutter/flutter/pull/173715
* [a11y] Add `expanded` flag support to Android. by @ksokolovskyi in https://github.com/flutter/flutter/pull/174981
* Migrate tests and documentation to set java version to 17 by @reidbaker in https://github.com/flutter/flutter/pull/176204
* Migrate java 11 usage to java 17 usage for templates by @reidbaker in https://github.com/flutter/flutter/pull/176203
* Update flutter test to use SemanticsFlags by @hannah-hyj in https://github.com/flutter/flutter/pull/175987
* Implement framework interface for the dialog window archetype by @mattkae in https://github.com/flutter/flutter/pull/176202
* Web semantics: Fix email field selection/cursor by using type="text" + inputmode="email" by @flutter-zl in https://github.com/flutter/flutter/pull/175876
* replace `onPop` usage with `onPopWithResult` in `navigation_bar.2.dart ` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/174841
* Adds dart ui API for setting application level locale by @chunhtai in https://github.com/flutter/flutter/pull/175100
* Update description in _LastFinderMixin to properly describe finding last by @FufferKS in https://github.com/flutter/flutter/pull/174232
* Fix: Update anchorRect for overlayBuilder when anchor moves by @rkishan516 in https://github.com/flutter/flutter/pull/169814
* Fix typo in pages.dart by @TDuffinNTU in https://github.com/flutter/flutter/pull/176438
* Selecting an implementation widget with the on-device inspector opens the code location for the nearest project widget by @elliette in https://github.com/flutter/flutter/pull/176530
#### Material
* Fix table cell semantics rect alignment issues. by @hannah-hyj in https://github.com/flutter/flutter/pull/174914
* Fix IconButton.color overrided by IconButtomTheme by @bleroux in https://github.com/flutter/flutter/pull/174515
* Fix DropdownMenuFormField does not clear text field content on reset … by @bleroux in https://github.com/flutter/flutter/pull/174937
* Migrate to widget state by @ValentinVignal in https://github.com/flutter/flutter/pull/174746
* Document Form.onChange precedence over DropdownButtonFormField.onChange by @bleroux in https://github.com/flutter/flutter/pull/175249
* Show cursor after swipe only if TextField has focus by @Memet18 in https://github.com/flutter/flutter/pull/175044
* Migrate to widget state by @ValentinVignal in https://github.com/flutter/flutter/pull/175242
* Fix default overlay color in `TabBar` by @ValentinVignal in https://github.com/flutter/flutter/pull/175270
* Allow Passing an AnimationController to CircularProgressIndicator and LinearProgressIndicator by @dkwingsmt in https://github.com/flutter/flutter/pull/174605
* Refactor: Migrate page transition builder class to widgets by @rkishan516 in https://github.com/flutter/flutter/pull/174321
* fix: ColorScheme will removeListener on imageStream twice if there is error loading the image. by @dkwingsmt in https://github.com/flutter/flutter/pull/174465
* Correct documentation in PredictiveBackFullscreenPageTransitionsBuilder by @xVemu in https://github.com/flutter/flutter/pull/174362
* feat: Enable WidgetStateColor to be used in ChipThemeData.deleteIconColor by @erickzanardo in https://github.com/flutter/flutter/pull/171646
* Migrate to WidgetState by @ValentinVignal in https://github.com/flutter/flutter/pull/175396
* Migrate to `WidgetPropertyResolver` by @ValentinVignal in https://github.com/flutter/flutter/pull/175397
* Fix InputDecoration does not apply errorStyle to error by @bleroux in https://github.com/flutter/flutter/pull/174787
* Make sure that a CloseButton doesn't crash in 0x0 environment by @ahmedsameha1 in https://github.com/flutter/flutter/pull/172902
* [a11y] TimePicker clock is unnecessarily announced by @bleroux in https://github.com/flutter/flutter/pull/175570
* Add `menuController` to `DropdownMenu` by @ValentinVignal in https://github.com/flutter/flutter/pull/175039
* Correctly implement PlatformViews' cursors on Web by @dkwingsmt in https://github.com/flutter/flutter/pull/174300
* Document how to hide counter in TextField.maxLength by @bleroux in https://github.com/flutter/flutter/pull/175797
* Make sure that a VerticalDivider doesn't crash at 0x0 environment by @ahmedsameha1 in https://github.com/flutter/flutter/pull/174761
* Make sure that Drawer & DrawerHeader don't crash in 0x0 environment by @ahmedsameha1 in https://github.com/flutter/flutter/pull/174772
* Broken link in NavigationRail documentation by @srivats22 in https://github.com/flutter/flutter/pull/175852
* feat(cupertino): Add selectableDayPredicate parameter to CupertinoDatePicker for selectable day control #171332 by @koukibadr in https://github.com/flutter/flutter/pull/171334
* Make sure that a MaterialApp doesn't crash in 0x0 environment by @ahmedsameha1 in https://github.com/flutter/flutter/pull/173090
* Make sure that a FlexibleSpaceBar doesn't crash in 0x0 environment by @ahmedsameha1 in https://github.com/flutter/flutter/pull/175228
* Migrate to `WidgetStateColor` by @ValentinVignal in https://github.com/flutter/flutter/pull/175573
* Add tests for InputDecoration borders (M3 and theme normalization) by @bleroux in https://github.com/flutter/flutter/pull/175838
* Reapply "Update the AccessibilityPlugin::Announce method to account f… by @mattkae in https://github.com/flutter/flutter/pull/174365
* [time_picker] refactor: Distinguish widgets for dial mode only by @Gustl22 in https://github.com/flutter/flutter/pull/173188
* Reverts "Reapply "Update the AccessibilityPlugin::Announce method to account f… (#174365)" by @auto-submit[bot] in https://github.com/flutter/flutter/pull/176059
* Add itemClipBehavior property for CarouselView's children by @AlsoShantanuBorkar in https://github.com/flutter/flutter/pull/175324
* Migrate to `WidgetStateMouseCursor` by @ValentinVignal in https://github.com/flutter/flutter/pull/175981
* Make sure that a DesktopTextSelectionToolbar doesn't crash in 0x0 env… by @ahmedsameha1 in https://github.com/flutter/flutter/pull/173928
* Enhance input decorator padding logic for character counter in text f… by @RootHex200 in https://github.com/flutter/flutter/pull/175706
* Migrate to `WidgetStateBorderSide` by @ValentinVignal in https://github.com/flutter/flutter/pull/176164
* Fix docs referencing deprecated radio properties by @victorsanni in https://github.com/flutter/flutter/pull/176244
* Migrate to `WidgetStateOutlinedBorder` by @ValentinVignal in https://github.com/flutter/flutter/pull/176270
* Migrate to `WidgetStateTextStyle` by @ValentinVignal in https://github.com/flutter/flutter/pull/176330
* Make sure that a DateRangePickerDialog doesn't crash in 0x0 environments by @ahmedsameha1 in https://github.com/flutter/flutter/pull/173754
* Make sure that a DrawerButton doesn't crash in 0x0 environment by @ahmedsameha1 in https://github.com/flutter/flutter/pull/172948
* Reapply "Update the AccessibilityPlugin::Announce method to account f… by @chunhtai in https://github.com/flutter/flutter/pull/176107
* Fix platform specific semantics for time picker buttons by @Piinks in https://github.com/flutter/flutter/pull/176373
* Update localization from translation console by @QuncCccccc in https://github.com/flutter/flutter/pull/176324
* Fix Voiceover traversal for OutlinedButton.icon by @LouiseHsu in https://github.com/flutter/flutter/pull/175810
* [material/menu_anchor.dart] Check for reserved padding updates on layout delegate.  by @davidhicks980 in https://github.com/flutter/flutter/pull/176457
* Fix TextFormField does not inherit local InputDecorationTheme by @bleroux in https://github.com/flutter/flutter/pull/176397
* Fix NavigatorBar lacks visual feedback by @bleroux in https://github.com/flutter/flutter/pull/175182
* Migrate to `WidgetStateInputBorder` by @ValentinVignal in https://github.com/flutter/flutter/pull/176386
* Fix PopupMenu does not update when PopupMenuTheme in Theme changes. by @ksokolovskyi in https://github.com/flutter/flutter/pull/175513
* Fix InputDecoration helper/error padding is not compliant by @bleroux in https://github.com/flutter/flutter/pull/176353
#### iOS
* Prevent potential crash when accessing window in FlutterSceneDelegate by @vashworth in https://github.com/flutter/flutter/pull/174873
* [ios] Do not re-add delaying recognizer on iOS 26 by @hellohuanlin in https://github.com/flutter/flutter/pull/175097
* Adds a11y section locale support for iOS by @chunhtai in https://github.com/flutter/flutter/pull/175005
* Filter out unexpected process logs on iOS with better regex matching. by @vashworth in https://github.com/flutter/flutter/pull/175452
* Connect the FlutterEngine to the FlutterSceneDelegate by @vashworth in https://github.com/flutter/flutter/pull/174910
* Do not present textures in FlutterMetalLayer if the drawable size changed and the texture's size does not match the new drawable size by @jason-simmons in https://github.com/flutter/flutter/pull/175450
* Ignore upcoming `experimental_member_use` warnings. by @stereotype441 in https://github.com/flutter/flutter/pull/175969
* Add scene plugin lifecycle events by @vashworth in https://github.com/flutter/flutter/pull/175866
* Roll GN to 81b24e01 by @jason-simmons in https://github.com/flutter/flutter/pull/176119
* Add SwiftUI support for UIScene migration by @vashworth in https://github.com/flutter/flutter/pull/176230
* Add deeplinking for UIScene migration by @vashworth in https://github.com/flutter/flutter/pull/176303
* Add state restoration for UIScene migration by @vashworth in https://github.com/flutter/flutter/pull/176305
* Add an AppDelegate callback for implicit FlutterEngines by @vashworth in https://github.com/flutter/flutter/pull/176240
* Add tooling to migrate to UIScene by @vashworth in https://github.com/flutter/flutter/pull/176427
* Handle FlutterEngine registration when embedded in Multi-Scene apps by @vashworth in https://github.com/flutter/flutter/pull/176490
* Add fallback for 'scene:willConnectToSession:options' by @vashworth in https://github.com/flutter/flutter/pull/176580
#### Android
* [Gradle 9] Removed `minSdkVersion` and only use `minSdk` by @jesswrd in https://github.com/flutter/flutter/pull/173892
* Fix GitHub labeler platform-android typo by @jmagman in https://github.com/flutter/flutter/pull/175076
* Update ImageReaderSurfaceProducer.MAX_IMAGES to include the maximum number of retained dequeued images by @jason-simmons in https://github.com/flutter/flutter/pull/174971
* fix typo in test documentation #2 by @AbdeMohlbi in https://github.com/flutter/flutter/pull/174707
* Update `build.gradle` to remove deprecation warning in `flutter\engine\src\flutter\shell\platform\android` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175305
* Remove redundant public modifier in `PlatformViewRenderTarget.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175284
* Refactor `AccessibilityBridge.java` to address linter issues by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175277
* Remove the unnecessary semicolon at the end of the line in `ProcessTextPlugin.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175280
* Replace `.size() == 0` with `isEmpty()` in `PlatformPlugin.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175285
* Remove unnecessary `toString()` call in `ImageReaderPlatformViewRenderTarget.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175286
* Remove  redundant `public` modifier  for interface members in MouseCursorPlugin.java by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175281
* fix typo in test documentation by @AbdeMohlbi in https://github.com/flutter/flutter/pull/174292
* replace ` Charset.forName("UTF-8")` with `StandardCharsets.UTF_8` to address linter issues by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175275
* Update `buildscript classpath dependency` to fix IDE support on android studio by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175273
* Fix linter issues about C-style array in java code  by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175497
* Remove unnecessary public modifier in `KeyboardManager.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175500
* [Android 16] Bump robolectric and java to 21 for `third_party` libraries by @ash2moon in https://github.com/flutter/flutter/pull/175550
* Update `KeyChannelResponder.java`  to use method reference  by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175510
* Remove unnecessary `String.valueOf` in `KeyboardManager.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175502
* Remove unused imports, fix assertion order, add non null annotations to `ImageReaderPlatformViewRenderTargetTest.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175723
* Simplify test asserts and use lambdas  by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175727
* Fix wrong order of asserts arguments by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175726
* Improve code quality in `AccessibilityBridgeTest.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175718
* Fix linter issues in `VsyncWaiterTest` Capital L for long values by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175780
* Simplify asserts in `FlutterMutatorTest` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175730
* Use `assertNull` to simplify code by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175720
* fix small typo in test docs by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175776
* Change the arguments order in `assertEquals` to fix linter issues by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175719
* Simplify/fix ordering of asserts in `TextInputPluginTest` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175784
* refactor code to use method reference and lambdas in `DartMessengerTest.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175731
* use lambda expressions /method reference to fix linter issue in `DartMessengerTest.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175733
* Replace curly braces with lambdas in `KeyEventChannelTest` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175729
* Refactor `FlutterInjectorTest` to use lambdas/method reference by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175777
* In Gradle Flutter task, correctly replace '\ ' with ' '. by @mboetger in https://github.com/flutter/flutter/pull/175815
* Improve code quality in `SensitiveContentPluginTest.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175721
* Add warn java evaluation to android_workflow by @reidbaker in https://github.com/flutter/flutter/pull/176097
* Clean up typos in `PlatformViewsControllerTest.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175725
* fix `assertEquals` arguments are in wrong order in `FlutterJNITest.java` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175728
* [Android] Use headingLevel for heading accessibility property by @mnayef95 in https://github.com/flutter/flutter/pull/175416
* Set minimum supported java version to 17  by @reidbaker in https://github.com/flutter/flutter/pull/176226
* Update Framework CI to Use NDK r28c by @jesswrd in https://github.com/flutter/flutter/pull/176214
* Fix deprecated configureStatusBarForFullscreenFlutterExperience for Android 15+ by @alexskobozev in https://github.com/flutter/flutter/pull/175501
#### Windows
* Rename DisplayMonitor to DisplayManager on Win32 by @mattkae in https://github.com/flutter/flutter/pull/175619
* [win32] Runloop should use high resolution timer and avoid deadlock by @knopp in https://github.com/flutter/flutter/pull/176023
#### Linux
* Warn if embedder API calls don't return success by @robert-ancell in https://github.com/flutter/flutter/pull/176184
#### Web
* [web] Minor simplification in flutter.js loader by @mdebbar in https://github.com/flutter/flutter/pull/174963
* [web] Fix image and color filters equality in SkWASM. by @ksokolovskyi in https://github.com/flutter/flutter/pull/175230
* Remove 'v' Open DevTools from help on web in profile/release mode by @danwirele in https://github.com/flutter/flutter/pull/172829
* [web] Remove unused `sceneHost` property by @mdebbar in https://github.com/flutter/flutter/pull/174997
* [web] Fix errors when using image filters with default values. by @ksokolovskyi in https://github.com/flutter/flutter/pull/175122
* [reland][web] Refactor renderers to use the same frontend code #174588 by @harryterkelsen in https://github.com/flutter/flutter/pull/175392
* Delete unused web_unicode library by @mdebbar in https://github.com/flutter/flutter/pull/174896
* [web] Fix assertion thrown when hot restarting during animation by @mdebbar in https://github.com/flutter/flutter/pull/175856
* web_ui: avoid crash for showPerformanceOverlay; log 'not supported' once by @muradhossin in https://github.com/flutter/flutter/pull/173518
* [web] Remove mention of non-existent `canvaskit_lock.yaml` by @mdebbar in https://github.com/flutter/flutter/pull/176108
* Update the test package for the web engine unit test bits. by @eyebrowsoffire in https://github.com/flutter/flutter/pull/176241
* [web] Bump Firefox to 143.0 by @mdebbar in https://github.com/flutter/flutter/pull/176110
* Remove references to dart:js_util by @fishythefish in https://github.com/flutter/flutter/pull/176323
#### Tooling
* [Tool] Remove leftover Android x86 deprecation warning constant by @bkonyi in https://github.com/flutter/flutter/pull/174941
* Make every LLDB Init error message actionable by @vashworth in https://github.com/flutter/flutter/pull/174726
* [web] Reuse chrome instance to run all flutter tests by @mdebbar in https://github.com/flutter/flutter/pull/174957
* [Widget Preview] Improve `--machine` output by @bkonyi in https://github.com/flutter/flutter/pull/175003
* Fix crash when attaching to a device with multiple active flutter apps by @chingjun in https://github.com/flutter/flutter/pull/175147
* Deprecate Objective-C plugin template by @okorohelijah in https://github.com/flutter/flutter/pull/174003
* [native_assets] Find more `CCompilerConfig` on Linux by @GregoryConrad in https://github.com/flutter/flutter/pull/175323
* Roll pub packages and update lockfiles by @gmackall in https://github.com/flutter/flutter/pull/175446
* Update gradle_utils.dart to use `constant` instead of `final` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175443
* Update gradle_errors.dart to use constants defined in gradle_utils.dart by @AbdeMohlbi in https://github.com/flutter/flutter/pull/174760
* fix typo in comments to mention `settings.gradle/.kts` instead of `build.gradle/.kts` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175486
* [Tool] Serve DevTools from DDS, remove ResidentDevToolsHandler by @bkonyi in https://github.com/flutter/flutter/pull/174580
* [Widget Preview] Don't update filtered preview set when selecting non-source files by @bkonyi in https://github.com/flutter/flutter/pull/175596
* Remove `name` field form `SupportedPlatform` enum by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175611
* Roll pub packages by @flutter-pub-roller-bot in https://github.com/flutter/flutter/pull/175545
* Update maximum known Gradle version to 9.1.0 by @bc-lee in https://github.com/flutter/flutter/pull/175543
* Fix typo in tests `README` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175788
* Roll `package:analyzer` forward to `8.2.0`. by @stereotype441 in https://github.com/flutter/flutter/pull/175849
* Remove comment about trailing commas from templates by @bkonyi in https://github.com/flutter/flutter/pull/175864
* Introduce a getter for `Project` to get `gradle-wrapper.properties` directly   by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175485
* [Widget Preview] Fix filter by file on Windows by @bkonyi in https://github.com/flutter/flutter/pull/175783
* Update AGP/Java/Gradle comparison when using analyze --suggestions by @reidbaker in https://github.com/flutter/flutter/pull/175808
* Update Flutter's templates to use dot shorthands by @loic-sharma in https://github.com/flutter/flutter/pull/175891
* Add kotlin/kgp 2.2.* evaluation criteria.  by @reidbaker in https://github.com/flutter/flutter/pull/176094
* Removes type annotations in templates by @Piinks in https://github.com/flutter/flutter/pull/176106
* Update java version ranges with the top end limitation for java pre 17 by @reidbaker in https://github.com/flutter/flutter/pull/176049
* [Widget Preview] Improve IDE integration support by @bkonyi in https://github.com/flutter/flutter/pull/176114
* Add tests for `Project` getters  by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175994
* [Widget Preview] Forward Widget Inspector navigation events via DTD by @bkonyi in https://github.com/flutter/flutter/pull/176218
* Stop using deprecated analyzer 7.x.y APIs. by @scheglov in https://github.com/flutter/flutter/pull/176242
* [native assets] Roll dependencies by @dcharkes in https://github.com/flutter/flutter/pull/176287
* [native assets] Enable build hooks and code assets on stable by @dcharkes in https://github.com/flutter/flutter/pull/176285
* [Tool / l10n] Fix issue where localization generator assumed current directory was the target project by @bkonyi in https://github.com/flutter/flutter/pull/175881
* [Widget Preview] Persist "Filter by Selected File" toggle by @bkonyi in https://github.com/flutter/flutter/pull/176289
* [Widget Preview] Fix resolution for workspace "hosted" dependencies by @bkonyi in https://github.com/flutter/flutter/pull/176358
* Upgrade packages by @mraleph in https://github.com/flutter/flutter/pull/176411
* [Widget Preview] Fix type error when retrieving flags from persistent preferences by @bkonyi in https://github.com/flutter/flutter/pull/176546
* [Widget Preview] Fix `WidgetInspectorService` override by @bkonyi in https://github.com/flutter/flutter/pull/176550
* Fix code style in Linux embedder template by @robert-ancell in https://github.com/flutter/flutter/pull/176256
* [Widget Preview] Rework UI and theming by @bkonyi in https://github.com/flutter/flutter/pull/176581
* [Tool] Output `app.dtd` and `app.devTools` in machine mode by @bkonyi in https://github.com/flutter/flutter/pull/176655
#### Other Changes
* Remove 'terms of use' wording from web_unicode by @mdebbar in https://github.com/flutter/flutter/pull/174939
* [a11y-app] Fix NavigationRail leading and trailing labels by @bleroux in https://github.com/flutter/flutter/pull/174861
* [Device Lab] Add regression testing for flutter/flutter#174952 by @bkonyi in https://github.com/flutter/flutter/pull/174956
* deletes the old license checker. by @gaaclarke in https://github.com/flutter/flutter/pull/174719
* Added note about how to compile licenses_cpp by @gaaclarke in https://github.com/flutter/flutter/pull/174947
* [ios26]fix host engine compile error by @hellohuanlin in https://github.com/flutter/flutter/pull/174723
* Define a concept for UniqueObjectTraits. by @chinmaygarde in https://github.com/flutter/flutter/pull/174905
* Impeller: Convert GLProc name field and GLErrorToString to std::string_view by @DEVSOG12 in https://github.com/flutter/flutter/pull/173771
* Bump actions/labeler from 5.0.0 to 6.0.1 in the all-github-actions group by @dependabot[bot] in https://github.com/flutter/flutter/pull/175093
* [shell] Fix engineId not being set after hot restart by @knopp in https://github.com/flutter/flutter/pull/174451
* update deps to point to the new SOT repo for package:coverage by @devoncarew in https://github.com/flutter/flutter/pull/175234
* Set Gemini Code Assist `include_drafts` to false by @jmagman in https://github.com/flutter/flutter/pull/175098
* Update Chromium sysroot to pick up RISC-V support. by @rmacnak-google in https://github.com/flutter/flutter/pull/173671
* Add a gn --ccache argument by @robert-ancell in https://github.com/flutter/flutter/pull/174621
* Merge the engine README into the README of the old buildroot. by @chinmaygarde in https://github.com/flutter/flutter/pull/175384
* Update NDK Scipt to Latest Stable Part 1 by @jesswrd in https://github.com/flutter/flutter/pull/175365
* [Impeller] Disable the render target cache when creating a snapshot in DlImageImpeller::MakeFromYUVTextures by @jason-simmons in https://github.com/flutter/flutter/pull/174912
* [docs] Add initial version of Flutter AI rules by @johnpryan in https://github.com/flutter/flutter/pull/175011
* [benchmarks] Allow passing --local-web-sdk and --build-mode flags to benchmarks by @harryterkelsen in https://github.com/flutter/flutter/pull/175199
* Sync 3.35.3 and 3.35.4 notes from stable to master by @gmackall in https://github.com/flutter/flutter/pull/175461
* Ensure that the raster thread has an EGL context before submitting the command buffer in ImageEncodingImpeller by @jason-simmons in https://github.com/flutter/flutter/pull/175102
* chore: update content workflow to use itnernal script by @jtmcdole in https://github.com/flutter/flutter/pull/175291
* Removes NOTICES from licenses input by @gaaclarke in https://github.com/flutter/flutter/pull/174967
* Added a 36 device for Firebase Lab Testing by @jesswrd in https://github.com/flutter/flutter/pull/175613
* [engine][fuchsia] Update to Fuchsia API level 28 and roll latest GN SDK by @Breakthrough in https://github.com/flutter/flutter/pull/175425
* [engine] Cleanup Fuchsia FDIO library dependencies by @Breakthrough in https://github.com/flutter/flutter/pull/174847
* fix(tool): Use merge-base for content hash in detached HEAD by @harryterkelsen in https://github.com/flutter/flutter/pull/175554
* Update rules to include extension rules by @johnpryan in https://github.com/flutter/flutter/pull/175618
* [a11y-app] Add label to TextFormField in AutoCompleteUseCase. by @ksokolovskyi in https://github.com/flutter/flutter/pull/175576
* Update `CODEOWNERS` (for dev-tooling) by @matanlurey in https://github.com/flutter/flutter/pull/175201
* Roll Packages from 3d5c4196d9c8 to 45c9a843859f by @stuartmorgan-g in https://github.com/flutter/flutter/pull/175794
* Update docs/engine/contributing/Compiling-the-engine.md with macOS build steps by @orestesgaolin in https://github.com/flutter/flutter/pull/175716
* [a11y-app] Fix Autocomplete semantics label by @bleroux in https://github.com/flutter/flutter/pull/175409
* Updates to flutter web triage links by @mdebbar in https://github.com/flutter/flutter/pull/175791
* Fixes SemanticsFlags.isLink mis-translated in dart ui ffi by @chunhtai in https://github.com/flutter/flutter/pull/175812
* Add google_fonts to team-framework triage guidelines by @tirth-patel-nc in https://github.com/flutter/flutter/pull/175675
* Put Linux firebase_release_smoke_test on bringup by @Piinks in https://github.com/flutter/flutter/pull/176043
* [Impeller] Optimize scale translate rectangle transforms by @flar in https://github.com/flutter/flutter/pull/171841
* Revert "[Impeller] Optimize scale translate rectangle transforms" by @flar in https://github.com/flutter/flutter/pull/176061
* Fix link to .gclient setup instructions by @gmackall in https://github.com/flutter/flutter/pull/176046
* [Impeller] Optimize scale translate rectangle transforms by @flar in https://github.com/flutter/flutter/pull/176123
* Revert "[Impeller] Optimize scale translate rectangle transforms" by @flar in https://github.com/flutter/flutter/pull/176161
* Fix name of driver file by @robert-ancell in https://github.com/flutter/flutter/pull/176186
* Update Engine CI to use NDK r28c  by @jesswrd in https://github.com/flutter/flutter/pull/175870
* User Invoke-Expression instead of call operator for nested Powershell scripts invocations (on Windows) by @aam in https://github.com/flutter/flutter/pull/175941
* fix typo in `Crashes.md` by @AbdeMohlbi in https://github.com/flutter/flutter/pull/175959
* Update changelog as on 3.35 branch by @justinmc in https://github.com/flutter/flutter/pull/176216
* BUILD.gn: Support LTO build on Linux by @markyang92 in https://github.com/flutter/flutter/pull/176191
* Reduce timeout for Linux web_tool_tests back to 60 by @mdebbar in https://github.com/flutter/flutter/pull/176286
* Add verbose logs to module_uiscene_test_ios by @vashworth in https://github.com/flutter/flutter/pull/176306
* Delete Skia-specific performance overlay implementation by @flar in https://github.com/flutter/flutter/pull/176364
* Windowing integration tests now await change futures if a changes is expected + commenting our erroneous icon in Runner.rc for win32 by @mattkae in https://github.com/flutter/flutter/pull/176312
* fix: delay exiting microbenchmark by @jtmcdole in https://github.com/flutter/flutter/pull/176477
* Align flutter dependencies with ones coming from dart. by @aam in https://github.com/flutter/flutter/pull/176475
* Starts updating the DEPS in preupload. by @gaaclarke in https://github.com/flutter/flutter/pull/176485
* fix: support older git (ubuntu 22.04) in content hash by @jtmcdole in https://github.com/flutter/flutter/pull/176321
* Roll vulkan-deps to a9e2ca3b by @jason-simmons in https://github.com/flutter/flutter/pull/176322
* updates docs for flutter engine footprint by @gaaclarke in https://github.com/flutter/flutter/pull/176217
* Bump customer tests.version to 986c4326b4e4bb4e37bc963c2cc2aaa10b943859 by @DanTup in https://github.com/flutter/flutter/pull/176594
* Bump the customer tests to pick up an update to Zulip's tests. by @stereotype441 in https://github.com/flutter/flutter/pull/176463
* Make it clear that you need to install clangd in VSCode intellisense c++ config by @gmackall in https://github.com/flutter/flutter/pull/176609
* Rename UIScene integration test projects and fix Xcode compatibility by @vashworth in https://github.com/flutter/flutter/pull/176635
* Roll Dart SDK to 3.10.0-290.1.beta by @iinozemtsev in https://github.com/flutter/flutter/pull/176629
* [3.38] Create `release-candidate-branch.version` & `engine.version` by @camsim99 in https://github.com/flutter/flutter/pull/176746
* Trigger an engine build for the 3.38 beta release by @camsim99 in https://github.com/flutter/flutter/pull/176842
* [CP-Beta] fix: content hash check for LUCI_CONTEXT (#176867) by @jtmcdole in https://github.com/flutter/flutter/pull/176883
* Update `engine.version` by @camsim99 in https://github.com/flutter/flutter/pull/176799
* Trigger engine build, and clean up trigger file by @justinmc in https://github.com/flutter/flutter/pull/177181
* 3.38.0 beta engine version by @justinmc in https://github.com/flutter/flutter/pull/177178

#### New Contributors
* @DEVSOG12 made their first contribution in https://github.com/flutter/flutter/pull/173771
* @rodrigogmdias made their first contribution in https://github.com/flutter/flutter/pull/174856
* @danwirele made their first contribution in https://github.com/flutter/flutter/pull/172829
* @Breakthrough made their first contribution in https://github.com/flutter/flutter/pull/175425
* @dixita0607 made their first contribution in https://github.com/flutter/flutter/pull/175256
* @korca0220 made their first contribution in https://github.com/flutter/flutter/pull/175773
* @tirth-patel-nc made their first contribution in https://github.com/flutter/flutter/pull/175675
* @muradhossin made their first contribution in https://github.com/flutter/flutter/pull/173518
* @markyang92 made their first contribution in https://github.com/flutter/flutter/pull/176191
* @RootHex200 made their first contribution in https://github.com/flutter/flutter/pull/175706
* @FufferKS made their first contribution in https://github.com/flutter/flutter/pull/174232
* @alexskobozev made their first contribution in https://github.com/flutter/flutter/pull/175501
* @TDuffinNTU made their first contribution in https://github.com/flutter/flutter/pull/176438

## Flutter 3.35 Changes

### [3.35.5](https://github.com/flutter/flutter/releases/tag/3.35.5)

 - [flutter/172105](https://github.com/flutter/flutter/issues/172105) Flutter view no longer hangs after multiple transitions on iOS add-to-app.
 - [flutter/173106](https://github.com/flutter/flutter/issues/173106) Multiple cursors display correctly.

### [3.35.4](https://github.com/flutter/flutter/releases/tag/3.35.4)
- [flutter/173474](https://github.com/flutter/flutter/issues/173474) - On all platforms PlatformDispatchers.instance.engineId no longer returns null after hot restart.
- [flutter/174513](https://github.com/flutter/flutter/issues/174513) - On iOS 26, fix a bug where platform view's gesture blocking fails and lets touches on Flutter views fall through to underlying platform views.

### [3.35.3](https://github.com/flutter/flutter/releases/tag/3.35.3)

- [flutter/172627](https://github.com/flutter/flutter/issues/172627) - Unnecessary output is printed in non-verbose mode.
- [flutter/173917](https://github.com/flutter/flutter/issues/173917) - On Android, `flutter build apk` may fail to calculate the version code when using `--build-number`.
- [flutter/174437](https://github.com/flutter/flutter/issues/174437) - When running a Flutter web application in debug mode, the console is spammed with non-fatal error messages.
- [flutter/174267](https://github.com/flutter/flutter/issues/174267) - Golden test failures can cause the test harness to stall.
- [flutter/171691](https://github.com/flutter/flutter/issues/171691) - A race condition can cause crashes in the Impeller Vulkan back end.
- [flutter/174100](https://github.com/flutter/flutter/issues/174100) - Superellipses may not render correctly when using Impeller.
- [flutter/174015](https://github.com/flutter/flutter/issues/174015) - Obsolete warning and error messages are shown when switching between build modes in Xcode.

### [3.35.2](https://github.com/flutter/flutter/releases/tag/3.35.2)

- [flutter/173823](https://github.com/flutter/flutter/issues/173823) - On Android builds that do not use flutter.minSdkVersion and do use a value lower than 24 in a kotlin build file, correct flutters auto migration to update value with kotlin syntax.
- [flutter/173741](https://github.com/flutter/flutter/issues/173741) - Fixes an issue that prevents (web) screen readers from pressing buttons through keyboard shortcuts.
- [flutter/173960](https://github.com/flutter/flutter/issues/173960) - Fixes an issue where starting a widget preview fails if Chrome or Edge is not installed.
- [flutter/174017](https://github.com/flutter/flutter/issues/174017) - Fixes an issue when running a 32-bit process on a 64-bit Windows system.
- [flutter/173895](https://github.com/flutter/flutter/issues/173895) - Don't crash widget preview when a directory watcher restarts on Windows.
- [flutter/171992](https://github.com/flutter/flutter/issues/171992) - Blocks `exynos9820` chip from using the Impeller Vulkan backend.
- [flutter/173959](https://github.com/flutter/flutter/issues/173959) - Fixes a null assertion when trying to add `@Preview()` to invalid nodes.
- [flutter/174184](https://github.com/flutter/flutter/pull/174184) - Fixes an issue where WASM builds were incorrectly triggered when dry run is disabled and --wasm is not specified.
- [flutter/171758](https://github.com/flutter/flutter/issues/171758) - Fixes an ExistingDartDevelopmentServiceException that could be thrown when running flutter run on a device with an existing Dart development service.

### [3.35.1](https://github.com/flutter/flutter/releases/tag/3.35.1)

- [flutter/173785](https://github.com/flutter/flutter/issues/173785) - Fixes an issue that prevented downloading the Flutter SDK for Windows from `flutter.dev`.

### [3.35.0](https://github.com/flutter/flutter/releases/tag/3.35.0)

Initial stable release.

## Flutter 3.32 Changes

### [3.32.8](https://github.com/flutter/flutter/releases/tag/3.32.8)

- [flutter/150131](https://github.com/flutter/flutter/issues/150131) iOS users on macOS 15 may see a tool crash if permissions are missing. Can work around by enabling mDNS permissions.
- [flutter/155294](https://github.com/flutter/flutter/issues/155294) [flutter/169506](https://github.com/flutter/flutter/issues/169506) On android Add a new api for requesting a new surface from the embedder that is different from any previously returned.
- [flutter/172602](https://github.com/flutter/flutter/pull/172602)  Do not call hasUnifiedMemory that was introduced in macOS 10.15 on versions before 10.15.
- [flutter/172250](https://github.com/flutter/flutter/issues/172250) `TextInput.hide` call incorrectly clears the text in the active text field on iOS.

### [3.32.7](https://github.com/flutter/flutter/releases/tag/3.32.7)

- [flutter/172121](https://github.com/flutter/flutter/pull/172121) - Fix iOS images replaced with pink fill when coming out of background.

### [3.32.6](https://github.com/flutter/flutter/releases/tag/3.32.6)

- [flutter/171106](https://github.com/flutter/flutter/pull/171106) - When a scroll view contains a `LayoutBuilder` on any platform, prevent null check crash.
- [flutter/171239](https://github.com/flutter/flutter/pull/171239) - When using Impeller + Vulkan and transitioning between activities that use Flutter on Android, prevent a crash.
- [flutter/171737](https://github.com/flutter/flutter/pull/171737) - When using platform views on Android SDK 10-13 (API 29-33) prevent app crash when backgrounding and then foregrounding app.

### [3.32.5](https://github.com/flutter/flutter/releases/tag/3.32.5)

- [flutter/170924](https://github.com/flutter/flutter/pull/170924) - Fix Flutter Windows on devices that only support OpenGL ES 2, like computers with Intel graphics cards.
- [flutter/170880](https://github.com/flutter/flutter/pull/170880) - Fixes unhandled exception on application shutdown in the debug adapter used by IDEs.
- [flutter/170846](https://github.com/flutter/flutter/pull/170846) - Fix image decode errors on iOS that could occur if a push notification triggered image decoding while the app is backgrounded.
- [flutter/171034](https://github.com/flutter/flutter/pull/171034) - Fixed an issue where iOS/macOS workflows may not behave as expected due to missing dev dependencies.

### [3.32.4](https://github.com/flutter/flutter/releases/tag/3.32.4)

- [flutter/170536](https://github.com/flutter/flutter/issues/170536) - Fixes a code-signing issue on Mac hosts when running `dart` tooling.

### [3.32.3](https://github.com/flutter/flutter/releases/tag/3.32.3)

- [flutter/170052](https://github.com/flutter/flutter/pull/170052) - Fixes "active" indicator for `NavigationBar` and `NavigationDrawer`
- [flutter/170013](https://github.com/flutter/flutter/pull/170013) - Fixes a memory leak in the Impeller Vulkan back end.
- [flutter/169912](https://github.com/flutter/flutter/pull/170003) - Fixes failures to build an Android AAB in release mode.

### [3.32.2](https://github.com/flutter/flutter/releases/tag/3.32.2)

- [flutter/169772](https://github.com/flutter/flutter/pull/169772) - Configuration changes for Flutter's CI to run tests on Linux instead of Windows when not otherwise required.
- [flutter/169630](https://github.com/flutter/flutter/pull/169630) - Fixes issue where flavored Android packages may not successfully build on Windows repeatedly until the next clean.
- [flutter/169912](https://github.com/flutter/flutter/pull/169912) - Splits Flutter CI task for publishing API docs into one build step and one deploy step.

### [3.32.1](https://github.com/flutter/flutter/releases/tag/3.32.1)

- [flutter/156793](https://github.com/flutter/flutter/issues/156793) - Fixes flaky crash when targeting web applications via IDEs using the DAP.
- [flutter/168849](https://github.com/flutter/flutter/issues/168849) - Fixes an issue rendering wide gamut images.
- [flutter/168846](https://github.com/flutter/flutter/issues/168846) - Fixes an issue displaying the wrong icons in the widget inspector for some apps.
- [flutter/167011](https://github.com/flutter/flutter/pull/167011) - Fixes Flutter Android builds for apps which use plugins with old Android Gradle Plugin versions.
- [flutter/169101](https://github.com/flutter/flutter/issues/169101) - Reduces the cost of running the (sometimes flaky) Linux fuchsia_test on release branches.
- [flutter/169318](https://github.com/flutter/flutter/issues/169318) - Fixed a bug where the flutter tool crash reporting did not include what plugins were being used by the current project.
- [flutter/169160](https://github.com/flutter/flutter/issues/169160) Fixed a bug where `appFlavor` is null after hot restarts or during `flutter test`.
- [flutter/167011](https://github.com/flutter/flutter/pull/167011) [Android] Fix regression in NDK version checking for projects with old AGP versions.
- [flutter/168847](https://github.com/flutter/flutter/pull/168847) [Widget Inspector] Fix missing cupertino icon in on-device inspector.

### [3.32.0](https://github.com/flutter/flutter/releases/tag/3.32.0)
Initial stable release.

## Flutter 3.29 Changes

### [3.29.3](https://github.com/flutter/flutter/releases/tag/3.29.3)
- [flutter/165818](https://github.com/flutter/flutter/pull/165818) - Unset `GIT_DIR` to enable flutter tool calls in githooks.
- [flutter/163421](https://github.com/flutter/flutter/issues/163421) - Impeller,
  Android, Fixes Android Emulator crash when navigating to routes with backdrop
  blurs.
- [flutter/165166](https://github.com/flutter/flutter/pull/165166) - Impeller, All platforms, Text that is scaled over 48x renders incorrectly.
- [flutter/163627](https://github.com/flutter/flutter/pull/163627) - Fix issue where placeholder types in ARB localizations weren't used for type inference, causing a possible type mismatch with the placeholder field defined in the template.
- [flutter/165166](https://github.com/flutter/flutter/pull/165166) - Update CI configurations and tests to use Xcode 16 and iOS 18 simulator.
- [flutter/161466](https://github.com/flutter/flutter/pull/161466) - Hot restart can hang on all platforms if "Pause on Unhandled Exceptions" is enabled by the debugger and a call to `compute` or `Isolate.run` has not completed.

### [3.29.2](https://github.com/flutter/flutter/releases/tag/3.29.2)

- [dart 3.7.2 changelog](https://github.com/dart-lang/sdk/blob/stable/CHANGELOG.md#372)
- [flutter/164958](https://github.com/flutter/flutter/issues/164958) - Impeller, All platforms, Text that is rotated 180 degrees exactly will render as if it is scaled by {-1, 1} instead of {-1, -1}.
- [flutter/165075](https://github.com/flutter/flutter/pull/165075) - Fixes crashes on Android devices older than API 29 when using Impeller OpenGLES.
- [flutter/164606](https://github.com/flutter/flutter/issues/164606) Fixes missing glyph error on Android and iOS devices using Impeller.
- [flutter/164036](https://github.com/flutter/flutter/pull/164036) - On iOS devices Increase number of concurrent background image decode tasks to partially mitigate "Image upload failed due to loss of GPU access" errors.
- [flutter/163175](https://github.com/flutter/flutter/pull/163175) - Improve performance of CanvasKit rendering for web.
- [flutter/164628](https://github.com/flutter/flutter/issues/164628) - iOS Fixes crash when allocation of surface for toImage/toImageSync fails.
- [flutter/164201](https://github.com/flutter/flutter/pull/164201) - Always use Android hardware buffers for platform views when supported.
- [flutter/164024](https://github.com/flutter/flutter/issues/164024): - Add back an empty io.flutter.app.FlutterApplication for Android apps post v2 embedder migration.
- [flutter/162198](https://github.com/flutter/flutter/issues/162198) - Fixes double-download of canvaskit.wasm
- [flutter/164392](https://github.com/flutter/flutter/pull/164392) - All platforms, Fixes a crash that can occur when animating and interacting with a scrollable simultaneously.

### [3.29.1](https://github.com/flutter/flutter/releases/tag/3.29.1)

- [flutter/163830](https://github.com/flutter/flutter/pull/163830) - Fix Tab linear and elastic animation blink.
- [flutter/164119](https://github.com/flutter/flutter/pull/164119) - Configuration changes to run test on macOS 14 for Flutter's CI.
- [flutter/164155](https://github.com/flutter/flutter/pull/164155) - Roll .ci.yaml changes into the LUCI configuration only when the master branch is updated.
- [flutter/164191](https://github.com/flutter/flutter/pull/164191) - Improve safaridriver launch process in Flutter's CI testing for web.
- [flutter/164193](https://github.com/flutter/flutter/pull/164193) - Provide guided error message when app crashes due to JIT restriction on iPhones.
- [flutter/164050](https://github.com/flutter/flutter/pull/164050) - Fixes test reorderable_list_test.dart failing for certain ordering seeds, such as 20250221.
- [flutter/163316](https://github.com/flutter/flutter/pull/163316) - Configuration changes to run test on macOS 14 for Flutter's CI.
- [flutter/163581](https://github.com/flutter/flutter/pull/163581) - Fix crash when using BackdropFilters in certain GLES drivers.
- [flutter/163616](https://github.com/flutter/flutter/pull/163616) - Disable Vulkan on known bad Xclipse GPU drivers for Android.
- [flutter/163666](https://github.com/flutter/flutter/pull/163666) - Always post new task during gesture dispatch to fix jittery scrolling on iOS devices.
- [flutter/163667](https://github.com/flutter/flutter/pull/163667) - Ensure that OpenGL "flipped" textures do not leak via texture readback.
- [flutter/163741](https://github.com/flutter/flutter/pull/163741) - Flutter tool respects tracked engine.version.
- [flutter/163754](https://github.com/flutter/flutter/pull/163754) - Fix text glitch when returning to foreground for Android.
- [flutter/163058](https://github.com/flutter/flutter/pull/163058) - Fixes jittery glyphs.
- [flutter/163201](https://github.com/flutter/flutter/pull/163201) - Fixes buttons with icons that ignore foregroundColor.
- [flutter/163265](https://github.com/flutter/flutter/pull/163265) - Disable Vulkan on known bad exynos SoCs for Android.
- [flutter/163261](https://github.com/flutter/flutter/pull/163261) - Fixes for Impeller DrawVertices issues involving snapshots with empty sizes.
- [flutter/163672](https://github.com/flutter/flutter/pull/163672) - Check for tracked engine.version before overriding.

### [3.29.0](https://github.com/flutter/flutter/releases/tag/3.29.0)
Initial stable release.

## Flutter 3.27 Changes

### [3.27.4](https://github.com/flutter/flutter/releases/tag/3.27.4)
- [flutter/162132](https://github.com/flutter/flutter/pull/162132) On all platforms DropdownMenu's menuChildren might be placed somewhere far from menuAnchor.

### [3.27.3](https://github.com/flutter/flutter/releases/tag/3.27.3)
- [flutter/159212](https://github.com/flutter/flutter/issues/159212) Track (via Google Analytics) if the Dart AOT Android "Deferred Components" feature is being meaningfully used.
- [flutter/160631](https://github.com/flutter/flutter/issues/160631) Fixes an issue with Material 3 Tab Bar animations.
- [flutter/159289](https://github.com/flutter/flutter/issues/159289) Fixes an issue with fullscreen route transitions.
- [flutter/162132](https://github.com/flutter/flutter/issues/162132) Fixes an issue that incorrectly positions `MenuAnchor`s in nested overlays.

### [3.27.2](https://github.com/flutter/flutter/releases/tag/3.27.2)

- [flutter/159729](https://github.com/flutter/flutter/issues/159729) Flutter module template triggers a warning when built for Android.
- [flutter/161176](https://github.com/flutter/flutter/issues/161176) Dropdown Menu can create an infinite loop.
- [flutter/161330](https://github.com/flutter/flutter/issues/161330) Using ScrollViewKeyboardDismissBehavior.onDrag in a SingleChildScrollView causes text fields to immediately unfocus if the keyboard opening scrolls the text field to keep it visible.
- [flutter/160127](https://github.com/flutter/flutter/issues/160127) Some Flutter web plugins do not add the `crossOrigin` property to <img> tags.
- [flutter/160155](https://github.com/flutter/flutter/issues/160155) Failed assertion in web engine: "The targeted input element must be the active input element".
- [flutter/160199](https://github.com/flutter/flutter/issues/160199) Some images on the web render blank.
- [flutter/160459](https://github.com/flutter/flutter/issues/160459) Incorrect Z order rendering in drawPoints may cause lines to overlap when one should be drawn in front of the other.
- [flutter/160409](https://github.com/flutter/flutter/issues/160409) App may crashes because of obsolete engine assertion.
- [flutter/158192](https://github.com/flutter/flutter/issues/158192) Positions of display cutouts on Android may not update - as returned by MediaQuery and used by SafeArea - upon screen orientation change.

### [3.27.1](https://github.com/flutter/flutter/releases/tag/3.27.1)

- [flutter/160041](https://github.com/flutter/flutter/issues/160041) - [Impeller][Android] Disables Impeller on older Android devices.
- [flutter/160206](https://github.com/flutter/flutter/issues/160206) - [Impeller][Android] Disables Android HardwareBuffer based swapchains on all devices.
- [flutter/160208](https://github.com/flutter/flutter/issues/160208) - [iOS] Fixes an issue on iOS preventing the ability to tap web view links in some plugins.

### [3.27.0](https://github.com/flutter/flutter/releases/tag/3.27.0)
Initial stable release.

## Flutter 3.24 Changes

### [3.24.5](https://github.com/flutter/flutter/releases/tag/3.24.5)
- [flutter/158125](https://github.com/flutter/flutter/pull/158125) - [iOS] Fixed a tool issue causing failures when `flutter build ios-framework --xcframework` copies Flutter debug symbols.
- [flutter/56301](https://github.com/flutter/engine/pull/56301) - [Android] Fixes a crash on Android devices when the surface is released unexpectedly when using PlatformView's.

### [3.24.4](https://github.com/flutter/flutter/releases/tag/3.24.4)
- [dart 3.5.4 changelog](https://github.com/dart-lang/sdk/blob/stable/CHANGELOG.md#354---2024-10-17)
- [flutter/154915](https://github.com/flutter/engine/pull/55366) - [macOS] Comply with the new Apple privacy manifest policy for the macOS Flutter engine framework and prevent the "Missing privacy manifest" warning when submitting a macOS app to the App Store.
- [flutter/153471](https://github.com/flutter/flutter/issues/153471) - [Tool] Fixes RPCError crash when setting up log filtering for Android devices.

### [3.24.3](https://github.com/flutter/flutter/releases/tag/3.24.3)
- [dart 3.5.3 changelog](https://github.com/dart-lang/sdk/blob/stable/CHANGELOG.md#353---2024-09-11)
- [flutter/154275](https://github.com/flutter/flutter/issues/154275) - [Android] Fixes performance issues on Android caused by engine threads not matching the core count.
- [flutter/154276](https://github.com/flutter/flutter/issues/154276) - [Impeller] Fixes an issue on iOS preventing mesh gradients from rendering correctly.
- [flutter/154349](https://github.com/flutter/flutter/issues/154349) - [Wasm] Fixes an issue on web causing Platform Views to break when compiled to Wasm.
- [flutter/154564](https://github.com/flutter/flutter/issues/154564) - [Impeller][iOS] Fixes an issue when using Impeller on iOS when using backdrop filters on older iPads, causing the GPU to hang.
- [flutter/154712](https://github.com/flutter/flutter/issues/154712) - [iOS] Fixes an issue on iOS causing video playback to flicker.
- [flutter/154892](https://github.com/flutter/flutter/issues/154892) - [Impeller][iOS] Fixes an issue when using Impeller on iOS causing a memory leak when using Platform Views.
- [flutter/154536](https://github.com/flutter/flutter/issues/154536) - [Tool] Fixes a CLI crash that occurs when shutting down after running a Flutter app on a browser.
- [flutter/154720](https://github.com/flutter/flutter/pull/154720) - Fixes an issue with the `Drawer` widget, causing it to open or close incorrectly.
- [flutter/154944](https://github.com/flutter/flutter/pull/154944) - [Tool] Fixes a Flutter tool crash that occurs when building Flutter modules for Android when using AGP 8.0+.

### [3.24.2](https://github.com/flutter/flutter/releases/tag/3.24.2)
- [Dart 3.5.2 Changelog](https://github.com/dart-lang/sdk/blob/stable/CHANGELOG.md#352---2024-08-28)
- [flutter/153949](https://github.com/flutter/flutter/issues/153949) - Fixes a crash on Android when deleting `EditableText` inside `CupertinoPageRoute`, with a CJK (chinese, japanese, korean) keyboard.
- [flutter/153939](https://github.com/flutter/flutter/issues/153939) - Fixes an issue on iOS where Flutter `TextField`s may stop accepting input.
- [flutter/152420](https://github.com/flutter/flutter/issues/152420) - Fixes scrolling jank on Android and iOS when a `SelectionArea`/`SelectableRegion` is used as a child of a Scrollable like `ListView` or `PageView`.
- [flutter/154199](https://github.com/flutter/flutter/pull/154199) - Removes excessive logging when building a freshly created template app for Android.
- [flutter/153967](https://github.com/flutter/flutter/pull/153967) - Fixes a host build failure on macOS when the `native assets` experiment is enabled, and there are no native asset frameworks to codesign.
- [flutter/153769](https://github.com/flutter/flutter/pull/153769) - When running a Flutter app, display a concise error message when connection to the device is lost.
- [flutter/154270](https://github.com/flutter/flutter/pull/154270) - Prevent preemptive gradle crash for android builds that would fail to build anyway but with a confusing error message.
- [flutter/54735](https://github.com/flutter/engine/pull/54735) - Fixes an error on Flutter Web where `onTap` is called twice on various widgets (`GestureDetector`, `InkWell`) when semantics are enabled.

### [3.24.1](https://github.com/flutter/flutter/releases/tag/3.24.1)

- [dart/56464](https://github.com/dart-lang/sdk/issues/56464) - Fixes resolving `include:` in `analysis_options.yaml` file in a nested folder in the workspace.
- [dart/56423](https://github.com/dart-lang/sdk/issues/56423) - Fixes source maps generated by `dart compile wasm` when optimizations are enabled.
- [dart/56374](https://github.com/dart-lang/sdk/issues/56374) - Fixes a bug in the `dart2wasm` compiler in unsound `-O3` / `-O4` modes where a implicit setter for a field of generic type will store null instead of the field value.
- [dart/56440](https://github.com/dart-lang/sdk/issues/56440) - Fixes a bug in the `dart2wasm` compiler that can trigger in certain situations when using partial instantiations of generic tear-offs (constructors or static methods) in constant expressions.
- [dart/56457](https://github.com/dart-lang/sdk/issues/56457) - The algorithm for computing the standard upper bound of two types, also known as UP, is provided the missing implementation for `StructuralParameterType` objects. In some corner cases the lacking implementation resulted in a crash of the compiler.
- [flutter/152047](https://github.com/flutter/flutter/issues/152047) - [Web] Fixes an issue in Flutter Web apps where when semantics are enabled, tapping on the label of a checkbox in a mobile browser won't togle the checkbox.
- [flutter/153308](https://github.com/flutter/flutter/issues/153308) - [Web] Adds source map support in `flutter run` / `flutter build` for `dart2wasm` for debugging in Chrome DevTools.
- [flutter/54446](https://github.com/flutter/engine/pull/54446) - [Web] Fixes an issue in Flutter Web apps where the app may crash if CanvasKit is loaded from the network instead of a cache.
- [flutter/152955](https://github.com/flutter/flutter/issues/152955) - [Impeller] Fixes an issue where when using unbound `saveLayers` rendering issues would occur.
- [flutter/153037](https://github.com/flutter/flutter/issues/153037) - [Impeller] Fixes an issue where RTL glyphs would render incorrectly.
- [flutter/153038](https://github.com/flutter/flutter/issues/153038) - [Impeller] Fixes an issue where padding would be applied incorrectly in `Canvas.drawVerticies` when using texture coordinates.
- [flutter/153041](https://github.com/flutter/flutter/issues/153041) - [Impeller] Fixes an rare issue causing applications to crash when using platform views on older iPhones.
- [flutter/153188](https://github.com/flutter/flutter/issues/153188) - [Impeller] Fixes a rendering issue on iOS devices using Impeller where clips do not appear around entities drawn with certain advanced blend modes.
- [flutter/54513](https://github.com/flutter/engine/pull/54513) - [iOS/MacOS] Fixes an issue preventing iOS Apps Store validation from failing for Flutter apps using Xcode versions before Xcode 16.
- [flutter/54518](https://github.com/flutter/engine/pull/54518) - Fixes an issue on OpenGL ES devices where a black screen would appear instead of the Flutter app output.
- [flutter/153117](https://github.com/flutter/flutter/pull/153117) [iOS/MacOS] Fixes an issue where compilation errors are not displayed in the output of `flutter run` when using Xcode 16.
- [flutter/153321](https://github.com/flutter/flutter/issues/153321) - [Desktop] Fixes an issue where older Windows devices could not run Flutter apps built using Flutter  3.21 or later.
- [flutter/153294](https://github.com/flutter/flutter/pull/153294) [Tool] Fixes an issue in the Flutter tool streamlining the crash message that occurs when running `flutter run -d chrome` and Chrome is closed before Flutter tries to close it.
- [flutter/153579](https://github.com/flutter/flutter/pull/153579) [Tool] Fixes an issue where users would experience large crash messages when `flutter run` or `flutter debug-adapter` are unable to connect to the Flutter web app.

### [3.24.0](https://github.com/flutter/flutter/releases/tag/3.24.0)
Initial stable release.

## Flutter 3.22 Changes

### [3.22.3](https://github.com/flutter/flutter/releases/tag/3.22.3) (July 17, 2024)

- [dart/55979](https://github.com/dart-lang/sdk/issues/55979) - Fixes an issue where `const bool.fromEnvironment('dart.library.ffi')` is true and conditional import condition `dart.library.ffi` is true in dart2wasm.
- [dart/55943](https://github.com/dart-lang/sdk/issues/55943) - Fixes an issue where FFI calls with variadic arguments on MacOS Arm64 would mangle the arguments.
- [flutter/149700](https://github.com/flutter/flutter/issues/149700) - [Impeller] Fixes rendering corruption when running on Intel mac simulators.
- [flutter/149701](https://github.com/flutter/flutter/issues/149701) - [Impeller] Fixes an issue on iOS that causese paths to render incorrectly.
- [flutter/149702](https://github.com/flutter/flutter/issues/149702) - [Impeller] Corrects and issue on iOs where coverage computation results in distored pixels in Impeller targets.
- [flutter/149704](https://github.com/flutter/flutter/issues/149704) - [Impeller] Fixes and issue on iOS where flickering may be occur when translating a blurred rounded rectangle.
- [flutter/149745](https://github.com/flutter/flutter/issues/149745) - [Impeller] Fixes a segfault on iOS when tessellating empty convex polygons.
- [flutter/149771](https://github.com/flutter/flutter/issues/149771) - [Impeller] Fixes a rendering error on iOS when advanced blend is double scaled.
- [flutter/53183](https://github.com/flutter/engine/pull/53183) - Fixes an issue where Linux apps show visual corruption on some frames.
- [flutter/149856](https://github.com/flutter/flutter/issues/149856) - Clarifies Flutter Fix log on how to update Kotlin Gradle Plugin that was introduced in Flutter 3.19.
- [flutter/150617](https://github.com/flutter/flutter/pull/150617) - Fixes a bug in `flutter test` where `--flavor` wasn't considered when validating cached assets, causing the flavor-conditional asset bundling feature to not work as expected.
- [flutter/150724](https://github.com/flutter/flutter/issues/150724) - Fixes an issue on Web+Linux that prevents users from inputting data using the numpad.
- [flutter/150787](https://github.com/flutter/flutter/pull/150787) - Fixes and issue on Windows when running certain commands, such as `flutter run` or `flutter build`, users get a lengthy crash message including the full contents of a FileSystemException.

### [3.22.2](https://github.com/flutter/flutter/releases/tag/3.22.2) (June 06, 2024)
* [dart/55818](https://github.com/dart-lang/sdk/issues/55818) - Fixes an issue where `DART_VM_OPTIONS` were not correctly parsed for standalone Dart executables created with `dart compile exe`.
* [dart/55873](https://github.com/dart-lang/sdk/issues/55873) - Fixes a bug in dart2wasm that can result in a runtime error that says `array.new_fixed()` has a constant larger than 10000.
* [dart/55894](https://github.com/dart-lang/sdk/issues/55894) - Adds support for `--enable-experiment` flag to `dart compile` wasm.
* [dart/55895](https://github.com/dart-lang/sdk/issues/55895) - Fixes an issue in dart2wasm compiler that can result in incorrect nullability of type parameter.
* [dart/55890](https://github.com/dart-lang/sdk/issues/55890) - Disallows `dart:ffi` imports in user code in dart2wasm as dart2wasm's currently only supports a small subset of `dart:ffi`.
* [flutter/148885](https://github.com/flutter/flutter/issues/148885) - Fixes a platform view issue on android 14 when multiple activities are used and `onMemoryTrim` is called.
* [flutter/149178](https://github.com/flutter/flutter/issues/149178) - Fixes an issue on iOS where users are unable to focus on a `TextField` or open the keyboard again after side pop from another screen.
* [flutter/149210](https://github.com/flutter/flutter/issues/149210) - Fixes an `EditableText` crash that occurs when a custom `TextEditingController` only implements the `TextEditingController` interface.
* [flutter/149588](https://github.com/flutter/flutter/issues/149588) - Fixes a crash that occurs when rendering children in `TwoDimentionalViewport` using keep alive widgets (e.g InkWell).
* [flutter/148916](https://github.com/flutter/flutter/pull/148916) - Fixes an issue in the `ColorScheme.fromSeed` method to respect the seed color even if the seed color is very bright.
* [flutter/149345](https://github.com/flutter/flutter/pull/149345) - Adds a service extension that DevTools uses to support a "Track widget build counts" feature in DevTools 2.36.0.
* [flutter/149378](https://github.com/flutter/flutter/pull/149378) - Fixes a focus issue on iOS and MacOS that causes `TextFields` to not function after cupertino back swipes.
* [flutter/52987](https://github.com/flutter/engine/pull/52987) - Fixes an issue on Android where platform view inputs are mapped to the wrong location.

### [3.22.1](https://github.com/flutter/flutter/releases/tag/3.22.1) (May 22, 2024)
* [dart/55714](https://github.com/dart-lang/sdk/issues/55714) - Fixes a bug in the CFE which could manifest as compilation errors of Flutter
  web apps when compiled with dart2wasm.
* [dart/55758](https://github.com/dart-lang/sdk/issues/55758) - Fixes a bug in the pub client, such that `dart run` will not interfere with
  Flutter l10n (at least for most cases).
* [flutter/147142](https://github.com/flutter/flutter/issues/147142) - Fixes a read/write permission issue when building Flutter apps for MacOS.

### [3.22.0](https://github.com/flutter/flutter/releases/tag/3.22.0) (May 14, 2024)
Initial stable release.

## Flutter 3.19 Changes

### [3.19.6](https://github.com/flutter/flutter/releases/tag/3.19.6) (April 17, 2024)
* [dart/55430](https://github.com/dart-lang/sdk/issues/55430) - Fixes an issue with JS interop in dart2wasm where JS interop methods that used the enclosing library‘s @JS annotation were actually using the invocation’s enclosing library's @JS annotation.
* [flutter/145563](https://github.com/flutter/flutter/issues/145563) - Fixes severe performance regression on Firefox in v. 3.19.
* [flutter/144439](https://github.com/flutter/flutter/issues/144439) - Removes the --enable-impeller run flag and FLTEnableImpeller plist key on iOS.

### [3.19.5](https://github.com/flutter/flutter/releases/tag/3.19.5) (March 28, 2024)
* [dart/55211](https://github.com/dart-lang/sdk/issues/55211) - Fixes an issue where dart vm crashed when running on pre-SSE41 older CPUs on Windows.

### [3.19.4](https://github.com/flutter/flutter/releases/tag/3.19.4) (March 21, 2024)
* [flutter/144211](https://github.com/flutter/flutter/issues/144211) - Reverts a clipping optimization that is broken when multiple clips are applied with a backdrop filter.
* [flutter/144213](https://github.com/flutter/flutter/issues/144213) - Fix flickering of gaussian blurs in scrolling containers.
* [dart/55158](https://github.com/dart-lang/sdk/issues/55158) - Fixes an exception when executing hot reload after making compilation-successful changes.
* [dart/55194](https://github.com/dart-lang/sdk/issues/55194) - ​​Fix crashes on web platforms that contains an extension type declaration where the extension type constructor invokes a redirecting factory in its initializer.
* [dart/55184](https://github.com/dart-lang/sdk/issues/55184) - Fix issues where it is unable to run commit queue and post-submit testing on beta and stable when Goma is shut down.
* [dart/55240](https://github.com/dart-lang/sdk/issues/55240) - ​​Fix DateTime.timeZoneName on Windows.

### [3.19.3](https://github.com/flutter/flutter/releases/tag/3.16.3) (March 07, 2024)
* [flutter/144565](https://github.com/flutter/flutter/issues/144565) - Fixes a tool crash when attempting to render a frame with raster stats on an application with the Impeller backend.
* [dart/55057](https://github.com/dart-lang/sdk/issues/55057) - Fixes an issue in dart2js where object literal constructors in interop extension types would fail to compile without an `@JS` annotation on the library.
* [dart/55095](https://github.com/dart-lang/sdk/issues/55095) - ​​Disallows certain types involving extension types from being used as the operand of an `await` expression, unless the extension type itself implements`Future`.

### [3.19.2](https://github.com/flutter/flutter/releases/tag/3.19.2) (February 28, 2024)
* [flutter/143886](https://github.com/flutter/flutter/issues/143886) - Fixes a parsing issue that caused the Flutter tool to crash in some circumstances.

### [3.19.1](https://github.com/flutter/flutter/releases/tag/3.19.1) (February 21, 2024)
* [flutter/143574](https://github.com/flutter/flutter/issues/143574) - Fixes an issue in Flutter web builds that disallowed the use of`--flavor` while launching.

## Flutter 3.16 Changes

### [3.16.9](https://github.com/flutter/flutter/releases/tag/3.16.9) (January 25, 2024)
* [dart/54699](https://github.com/dart-lang/sdk/issues/54699) - Fix an issue that causes Flutter apps to freeze when breakpoints are added to multiple isolates at the same time and an issue that causes Flutter apps to crash during hot reload.

### [3.16.8](https://github.com/flutter/flutter/releases/tag/3.16.8) (January 17, 2024)
* [dart/54494](https://github.com/dart-lang/sdk/issues/54494) - Fix Dart2js stack overflow in value range analysis.

### [3.16.7](https://github.com/flutter/flutter/releases/tag/3.16.7) (January 11, 2024)
* [dart/54427](https://github.com/dart-lang/sdk/issues/54427) - Upgrades Dart DevTools to version 2.28.5.
* [dart/54428](https://github.com/dart-lang/sdk/issues/54428) - Fixes an issue with serving static DevTools assets.

### [3.16.6](https://github.com/flutter/flutter/releases/tag/3.16.6) (January 10, 2024)
* [flutter/141017](https://github.com/flutter/flutter/issues/141017) - Migrates event sent with every command for analytics.
* [flutter/136060](https://github.com/flutter/flutter/issues/136060) - Fixes Xcode 15 crashes EXC_BAD_ACCESS when using the Networking framework.
* [flutter/140416](https://github.com/flutter/flutter/issues/140416) - Fixes PathNotFoundException deleting temp dir in IOSCoreDeviceControl._listCoreDevices.
* [dartlang/webdev/2297](https://github.com/dart-lang/webdev/issues/2297) - Fixes DWDS error when debugging on web.

### [3.16.5](https://github.com/flutter/flutter/releases/tag/3.16.5) (December 20, 2023)
* [flutter/138711](https://github.com/flutter/flutter/issues/138711) - Fixes AvailabilityVersionCheck failure on iOS
* [flutter/139571](https://github.com/flutter/flutter/issues/139571) - Fixes AnimatedOpacity affecting blended color overlay render
* [flutter/139294](https://github.com/flutter/flutter/issues/139294) - Fixes ImageFiltered flickers when widget is rendered on top
* [flutter/138193](https://github.com/flutter/flutter/issues/138193) - Fixes testMultiplePlatformViewsWithOverlays test on MacOS

### [3.16.4](https://github.com/flutter/flutter/releases/tag/3.16.4) (December 13, 2023)
* [flutter/139180](https://github.com/flutter/flutter/issues/139180) - Fix tool crash on flutter create when unable to run Java.
* [flutter/138434](https://github.com/flutter/flutter/issues/138434) - Fix tool crash on deleting directories that do not exist
* [flutter/135277](https://github.com/flutter/flutter/issues/135277) - Eliminates an excessive amount of Xcode error/warning output to the console when building or running macOS Flutter apps.

### [3.16.3](https://github.com/flutter/flutter/releases/tag/3.16.3) (December 5, 2023)
* [CVE-2023-6345](https://nvd.nist.gov/vuln/detail/CVE-2023-6345) - Skia fix for possible integer overflow on Canvas calls with user generated data
* [flutter/138550](https://github.com/flutter/flutter/issues/138550) - Fixes crash on iPad when selection "Share..." from selection controls.
* [flutter/138842](https://github.com/flutter/flutter/issues/138842) - Fix rendering bug with elevation 0 material components.
* [flutter/138850](https://github.com/flutter/flutter/issues/138850) - Add ability to customize NavigationBar indicator overlay and fixes a bug with the indicator shape.
* [dart/53086](https://github.com/dart-lang/sdk/issues/53086) - DDS fix to ensure threadID integers are serialized correctly by Debug Adapter Protocol (DAP) clients.
* [dart/53999](https://github.com/dart-lang/sdk/issues/53999) - Adjusts the nullablity computations in the implementation of the upper bound algorithm in the CFE
* [dart/54112](https://github.com/dart-lang/sdk/issues/54112) - Fixes missing closure code completion entries for function parameters for LSP-based editors like VS Code.

### [3.16.2](https://github.com/flutter/flutter/releases/tag/3.16.2) (November 30, 2023)
* [flutter/138535](https://github.com/flutter/flutter/issues/138535) - Fixes android execution failed for task ':app:mergeDebugNativeLibs'.
* [flutter/138598](https://github.com/flutter/flutter/issues/138598) - Fixes SVG rendering issue on IOS.

### [3.16.1](https://github.com/flutter/flutter/releases/tag/3.16.1) (November 27, 2023)
* [flutter/138030](https://github.com/flutter/flutter/issues/138030) - Fixes file deletion crash which can occur during iOS archive.
* [flutter/134716](https://github.com/flutter/flutter/issues/134716) - Fix iOS 17 keyboard freeze when switching languages
* [flutter/138180](https://github.com/flutter/flutter/issues/138180) - Prevents a crash in flutter doctor for macOS users who have an IntelliJ or Android Studio installation with a missing CFBundleIdentifier in its plist.
* [flutter/138040](https://github.com/flutter/flutter/issues/138040) - Ignore exceptions in Flutter tool when trying to set the echo mode of the terminal when the STDIN pipe has been broken.
* [flutter/124145](https://github.com/flutter/flutter/issues/124145) - Fixes a JSON array parsing bug that causes seg fault when --coverage is used

### [3.16.0](https://github.com/flutter/flutter/releases/tag/3.16.0) (Nov 15, 2023)
Initial stable release.

## Flutter 3.13 Changes

### [3.13.9](https://github.com/flutter/flutter/releases/tag/3.13.9) (October 25, 2023)
* [dart/53784](https://github.com/dart-lang/sdk/issues/53784) - [dart2js] Fixes compatibility with Node.js 21

### [3.13.8](https://github.com/flutter/flutter/releases/tag/3.13.8) (October 18, 2023)
* [dart/53747](https://github.com/dart-lang/sdk/issues/53747) -  Fixes a visual issue in the Dart VM preventing users from seeing variable values when debugging.
* [flutter/136552](https://github.com/flutter/flutter/issues/136552) - [iOS] Fixes issues with voice over when visiting a PlatformView in iOS applications.
* [flutter/136654](https://github.com/flutter/flutter/issues/136654) - [Android] Fixes rendering issues when using PlatformViews in Android applications on high refresh rate phones.

### [3.13.7](https://github.com/flutter/flutter/releases/tag/3.13.7) (October 11, 2023)
* [flutter/135442](https://github.com/flutter/flutter/issues/135442) - Fix Xcode 15 launch failure with iOS 17

### [3.13.6](https://github.com/flutter/flutter/releases/tag/3.13.6) (September 27, 2023)
* [flutter/133013](https://github.com/flutter/flutter/issues/133013) - [Impeller] Fix issues with PNG decompression
* [flutter/132838](https://github.com/flutter/flutter/issues/132838)  - Fix clip Imagefilter.blur on iOS
* [dart/53579](https://github.com/dart-lang/sdk/issues/53579) - Fixes a compiler crash when using @staticInterop or @anonymous factory constructors with type parameters.
* [dart/53503](https://github.com/dart-lang/sdk/issues/53503) - Fixes segmentation faults that terminate processes when encountering handled exceptions in the FFI library.
* [dart/53541](https://github.com/dart-lang/sdk/issues/53541) - Fixes slow variable access while debugging Flutter applications.

### [3.13.5](https://github.com/flutter/flutter/releases/tag/3.13.5) (September 20, 2023)
* [flutter/134825](https://github.com/flutter/flutter/issues/134825) - Fixes an issue where apps built in profile mode would not install or run on physical iOS 17 devices.
* [flutter/45598](https://github.com/flutter/engine/pull/45598) - Fix permissions on macos artifacts making mac framework readable and executable by all

### [3.13.4](https://github.com/flutter/flutter/releases/tag/3.13.4) (September 13, 2023)
* [dart/53449](https://github.com/dart-lang/sdk/issues/53449) - Fixes a dart2js issue causing a compiler crash when using a typed record pattern outside of the scope of a function body.
* [dart/53450](https://github.com/dart-lang/sdk/issues/53450) - Fixes a pause in the debugger when reaching an unhandled exception.
* [flutter/133658](https://github.com/flutter/flutter/issues/133658) - Fixes crash when using the --analyze-size argument.
* [flutter/133890](https://github.com/flutter/flutter/issues/133890) - Fixes incorrect autocorrect highlights in text fields in iOS 17.
* [flutter/134468](https://github.com/flutter/flutter/issues/134468) - Fixes an issue where users are not able to input text for IME language in iOS 17.
* [flutter/45742](https://github.com/flutter/engine/pull/45742) - Fixes CVE-2023-4863 - Security vulnerability in WebP.

### [3.13.3](https://github.com/flutter/flutter/releases/tag/3.13.3) (September 7, 2023)

* [flutter/133147](https://github.com/flutter/flutter/issues/133147) - fixes image-picker crashes on iOS
* [flutter/133069](https://github.com/flutter/flutter/issues/133069) - fixes issue where console prints dart:ui_web warnings in new flutter project
* [flutter/133441](https://github.com/flutter/flutter/issues/133441) - fixes issue where `flutter upgrade` crashes and reports "unknown flutter tag".
* [flutter/133055](https://github.com/flutter/flutter/issues/133055) - fixes issue where running `flutter doctor` crashes on FileSystemException
* [flutter/132788](https://github.com/flutter/flutter/issues/132788) - fixes a visual overflow caused by SliverMainAxisGroup where clip behavior isn’t applied

### [3.13.2](https://github.com/flutter/flutter/releases/tag/3.13.2) (August 30, 2023)

* [flutter/132764](https://github.com/flutter/flutter/pull/132764) - Fixes lower bound of children from TwoDimensionalChildBuilderDelegate.

### [3.13.1](https://github.com/flutter/flutter/releases/tag/3.13.1) (August 23, 2023)

* [flutter/132883](https://github.com/flutter/flutter/issues/132883) - Fixes an issue where Flutter apps would not compile when using custom icon fonts that contain spaces.
* [flutter/132959](https://github.com/flutter/flutter/issues/132959) - Fixes an issue where macOS applications using plugins with Xcode 15 would not compile.
* [flutter/132763](https://github.com/flutter/flutter/issues/132763) - Fixes auto-correction position in iOS 17.
* [flutter/132982](https://github.com/flutter/flutter/issues/132982) - [Impeller] Fixes an issue where applications would freeze if the app was minimized while an animation was occurring.

## Flutter 3.10 Changes

### [3.10.6](https://github.com/flutter/flutter/releases/tag/3.10.6) (July 12, 2023)

* [flutter/129161](https://github.com/flutter/flutter/issues/129161) - Fix regression in the GestureRecognizers used by the TextField where it would not fire the onTapDown or onTapUp callbacks which made selection not work
* [flutter/130084](https://github.com/flutter/flutter/issues/130084) - Using canvas.drawPicture where the nested picture fails to restore clips established in the child picture and makes content disappear.
* [dart/52767](https://github.com/dart-lang/sdk/issues/52767) - Fixes a flow in flow analysis that causes it to sometimes ignore destructuring assignments.
* [dart/52869](https://github.com/dart-lang/sdk/issues/52869) - Fixes an infinite loop in some web development compiles that include `is` or `as` expressions involving record types with named fields.
* [dart/52791](https://github.com/dart-lang/sdk/issues/52791) - Fixes a memory leak in Dart analyzer's file-watching.
* [dart/52793](https://github.com/dart-lang/sdk/issues/52793) - Fixes a memory leak of file system watcher related data structures.

### [3.10.5](https://github.com/flutter/flutter/releases/tag/3.10.5) (June 14, 2023)

* [flutter/127628](https://github.com/flutter/flutter/pull/127628) -  Fixes an issue preventing the use of `integration_test` when using AGP 8.0.
* [flutter/126043](https://github.com/flutter/flutter/issues/126403) - Fixes an error encountered when attempting to use `add-to-app` on Android when generating Flutter modules.
* [flutter/127090](https://github.com/flutter/flutter/issues/127090) - Fixes an issue preventing assets from being displayed properly on low pixel density devices.
* [flutter/128320](https://github.com/flutter/flutter/issues/128230) - Fixes an issue where image assets are not displayed when serving with Microsoft IIS.
* [dart/52403](https://github.com/dart-lang/sdk/issues/52403) - Fixes a bad cast in the frontend which can manifest as a crash in the dart2js
`ListFactorySpecializer` during Flutter web builds.
* [dart/1224](https://github.com/dart-lang/dart_style/issues/1224) - Handles formatting nullable record types with no fields.
* [dart/52480](https://github.com/dart-lang/sdk/issues/52480) - Fixes error when using records when targeting the web in development mode.

### [3.10.4](https://github.com/flutter/flutter/releases/tag/3.10.4) (June 07, 2023)

* [flutter/127836](https://github.com/flutter/flutter/issues/127836) - Fixes SliverAppBar's FlexibleSpaceBar overlaps


### [3.10.3](https://github.com/flutter/flutter/releases/tag/3.10.3) (June 02, 2023)

* [flutter/126435](https://github.com/flutter/flutter/issues/126435) - Fixes the position of `SearchAnchor` when used in a nested navigator.
* [flutter/127486](https://github.com/flutter/flutter/issues/127486) - [Impeller] Fixes an issue causing noise when using combinations of UV mapping and color blending.
* [flutter/126878](https://github.com/flutter/flutter/issues/126878) - [Impeller] Fixes an issue where images do not appear on iOS devices.
* [flutter/1127587](https://github.com/flutter/flutter/issues/124612) - [Impeller] Fixes a crash when applying backdrop blurs to platform views.
* [flutter/127103](https://github.com/flutter/flutter/issues/127103) - [Impeller] Fixes an issue where text is not rendered correctly when a transform is applied.
* [flutter/126487](https://github.com/flutter/flutter/issues/126487) - [Impeller] Fixes an issue where blur is not respected at certain value.
* [dart/52449](https://github.com/dart-lang/sdk/issues/52449) - Fixes an AOT compiler crash when generating an implicit getter returning an unboxed record.
* [dart/52373](https://github.com/dart-lang/sdk/issues/52373) - Fixes a situation in which variables appearing in multiple branches of an or-pattern might be erroneously reported as being mismatched.
* [dart/52334](https://github.com/dart-lang/sdk/issues/52334) - Adds missing `interface` modifiers on the purely abstract classes `MultiStreamController`, `StreamConsumer`, `StreamIterator` and `StreamTransformer`.
* [dart/52373](https://github.com/dart-lang/sdk/issues/52373) - Fixes an error during debugging when `InternetAddress.tryParse` is used.
* [dart/126884](https://github.com/flutter/flutter/issues/126884) - Fixes a VM issue causing crashes on hot reload.
* [dart/4195](https://github.com/dart-lang/linter/issues/4195) - Improves linter support.
* [dart/52439](https://github.com/dart-lang/sdk/issues/52439) - Fixes an issue in variable patterns preventing users from expressing a pattern match using a variable or wildcard pattern with a nullable record type.
* [dart/52386](https://github.com/dart-lang/sdk/issues/52386) - Updates warnings and provide instructions for updating the Dart pub cache on Windows.

### [3.10.2](https://github.com/flutter/flutter/releases/tag/3.10.2) (May 24, 2023)
This hotfix release addresses the following issues:
* [flutter/126532](https://github.com/flutter/flutter/issues/126532) - [Impeller] Fixes saveLayer ignores opacity of paint with blend mode lighten.
* [flutter/126739](https://github.com/flutter/flutter/issues/126739) - [Impeller] Fixes ImageShader alignment is different for different PaintingStyle.
* [flutter/126701](https://github.com/flutter/flutter/issues/126701) - [Impeller] Fixes InkSparkle splash not clipping on iOS.
* [flutter/126661](https://github.com/flutter/flutter/issues/126661) - Fixes PointerInterceptor reverses transformHitTests in a scaled context.
* [flutter/127183](https://github.com/flutter/flutter/issues/127183) - [Impeller] Fixes drawing path with image shader is not correct.
* [dart/52438](https://github.com/dart-lang/sdk/issues/52438) - Fixes a dart2js crash when using a switch case expression on a record where the fields don't match the cases.
* [dart/3392](https://github.com/dart-lang/dartdoc/issues/3392) - Add chips for class and mixin pages on dartdoc generated pages.
* [dart/52352](https://github.com/dart-lang/sdk/issues/52352) - Fixes a situation causing the parser to fail resulting in an infinite loop leading to higher memory usage.
* [dart/52078](https://github.com/dart-lang/sdk/issues/52078) -  Add clear errors when mixing inheritance in pre and post Dart 3 libraries.


### [3.10.1](https://github.com/flutter/flutter/releases/tag/3.10.1) (May 17, 2023)

This hotfix release addresses the following issues:
* [flutter/126510](https://github.com/flutter/flutter/issues/125276) - [Impeller] Fixes errors in text transformation when using impeller.
* [flutter/126854](https://github.com/flutter/flutter/issues/126854) - [Impeller] Fixes visual glitches and crashes when using wide gamut color support on iOS.
* [flutter/124883](https://github.com/flutter/flutter/issues/124883) - Fixes an issue where images do not render on Flutter web apps when the host machine has Internet Download Manager installed.
* [flutter/126491](https://github.com/flutter/flutter/issues/126491) - Fixes an issue where `CupertinoPicker` and `ListWheelViewport` crash with certain configurations on development builds.
* [flutter/124529](https://github.com/flutter/flutter/issues/124529) - Fixes an issue where iOS and macOS apps will not build when using Xcode 14.3 and adding dependencies with low iOS target versions.
* [flutter/122376](https://github.com/flutter/flutter/issues/122376) - Adds a migrator to update the Gradle version when it conflicts with the Android Studio version of Java is detected.
* [dart/124369](https://github.com/flutter/flutter/issues/124369) - Fixes a compiler crash involving redirecting factories and FFI.
* [dart/51899](https://github.com/dart-lang/sdk/issues/51899) - Fixes a dart2js crash when using a combination of local functions, generics, and records.
* [dart/52191](https://github.com/dart-lang/sdk/issues/52191) - Fixes incorrect error using a void in a switch case expression.
* [dart/52041](https://github.com/dart-lang/sdk/issues/52041) - Fixes a false error when using in switch case expressions when the switch refers to a private getter.
* [dart/52260](https://github.com/dart-lang/sdk/issues/52260) - Prevent the use of when and as as variable names in patterns.
* [dart/52241](https://github.com/dart-lang/sdk/issues/52241) - Fixes an inconsistency in type promotion between the analyzer and VM.
* [dart/1212](https://github.com/dart-lang/dart_style/issues/1212) - Improve performance on functions with many parameters.

### [3.10.0](https://github.com/flutter/flutter/releases/tag/3.10.0) (May 10, 2023)
Initial stable release.

## Flutter 3.7 Changes

### [3.7.12](https://github.com/flutter/flutter/releases/tag/3.7.12) (Apr 19, 2023)

This hotfix release addresses the following issues:

* [flutter/124838](https://github.com/flutter/flutter/issues/124838) - Support Gradle 8

### [3.7.11](https://github.com/flutter/flutter/releases/tag/3.7.11) (Apr 12, 2023)

This hotfix release addresses the following issues:

* [flutter/124529](https://github.com/flutter/flutter/issues/124529) - Fix Xcode 14.3 will not build when plugin transitive dependencies have a low deployment target
  * [flutter/124340](https://github.com/flutter/flutter/issues/124340) - Fixes an issue where iOS and MacOS fail to build when targeting low deployment targets when using xCode 14.3.
* [flutter/124208](https://github.com/flutter/flutter/issues/124208) - Fix orientation preferences on iOS 16+
  * [flutter/116711](https://github.com/flutter/flutter/issues/116711) - Fixes an issue where orientation preferences are not respected on iOS 16 and above.
* [flutter/124403](https://github.com/flutter/flutter/issues/124403) - Clarify errors around Java/Gradle incompatibility
  * [flutter/122376](https://github.com/flutter/flutter/issues/122376) - Clarify errors around Java/Gradle incompatibility.

### [3.7.10](https://github.com/flutter/flutter/releases/tag/3.7.10) (Apr 05, 2023)
This hotfix release addresses the following issues:
* [flutter/123890](https://github.com/flutter/flutter/issues/123890) - Fixes an issue where upgrading to Xcode 14.3 breaks the ability to publish iOS and macOS applications.

### [3.7.9](https://github.com/flutter/flutter/releases/tag/3.7.9) (Mar 30, 2023)
This hotfix release addresses the following issues:
* [dart/51798](https://github.com/dart-lang/sdk/issues/51798) - Fixes a false `Out of Memory` exception causing slowdowns.

### [3.7.8](https://github.com/flutter/flutter/releases/tag/3.7.8) (Mar 22, 2023)
This hotfix release addresses the following issues:
* [flutter/119441](https://github.com/flutter/flutter/issues/119441) - Fixes an issue where the `Toolbar` widget is incorrectly positioned when inside of a textfield in the Appbar.

### [3.7.7](https://github.com/flutter/flutter/releases/tag/3.7.7) (Mar 08, 2023)
This hotfix release addresses the following issues:
* [flutter/121256](https://github.com/flutter/flutter/issues/121256) - Fixes an issue where Android users can not use add2app because it can not locate build/host/apk/app-debug.apk.
* [engine/120455](https://github.com/flutter/flutter/issues/120455)
Cached DisplayList opacity inheritance fix.
* [dart/121270](https://github.com/flutter/flutter/issues/121270) - Fixes mobile device VM crashes caused by particular use of RegExp on mobile devices.

### [3.7.6](https://github.com/flutter/flutter/releases/tag/3.7.6) (Mar 01, 2023)
This hotfix release addresses the following issues:
* [dart/50981](https://github.com/dart-lang/sdk/issues/50981) - Improve performance of Dart Analysis Server by limiting the analysis context to 1.
* [dart/51481](https://github.com/dart-lang/sdk/issues/51481) - Update DDC test and builder configuration
* [flutter/114031](https://github.com/flutter/flutter/issues/114031) - Fixes a crash when using `flutter doctor --android-licenses` on macOS.
* [flutter/106674](https://github.com/flutter/flutter/issues/106674) - Fixes an issue where Flutter is unable to find the current JDK in specific versions of Android Studio.

### [3.7.5](https://github.com/flutter/flutter/releases/tag/3.7.5) (Feb 22, 2023)
This hotfix release addresses the following issues:
* [flutter/119180](https://github.com/flutter/flutter/issues/119180) - Apple Pencil writes on Flutter apps instead of scrolling when outside of a text field.
* [flutter/120220](https://github.com/flutter/flutter/issues/120220) - [Impeller] Flutter apps may crash when some clip operations are used.

### [3.7.4](https://github.com/flutter/flutter/releases/tag/3.7.4) (Feb 21, 2023)
This hotfix release addresses the following issues:
* [flutter/116360](https://github.com/flutter/flutter/issues/116360) - Flutter web apps will not load if accessed through any other path than `/`.
* [flutter/119557](https://github.com/flutter/flutter/issues/119557) - Localization files incorrectly overridden stopping Flutter applications from running.
* [flutter/116459](https://github.com/flutter/flutter/issues/116459) - Localization files do not parse when using numbers as select cases.

### [3.7.3](https://github.com/flutter/flutter/releases/tag/3.7.3) (Feb 9, 2023)
This hotfix release addresses the following issues:
* [flutter/119507](https://github.com/flutter/flutter/issues/119507) - Asset inclusion regression can cause unexpected app bundle size increase
* [flutter/119289](https://github.com/flutter/flutter/issues/119289) - [Impeller] ImageFilter.blur Edge sampling issue.
* [flutter/119950](https://github.com/flutter/flutter/issues/119950) - [Impeller] Improve blur performance for Android and iPad Pro.
* [flutter/119190](https://github.com/flutter/flutter/pull/119190) - Fix lexer issue where select/plural/other/underscores cannot be in identifier names.

### [3.7.2](https://github.com/flutter/flutter/releases/tag/3.7.2) (Feb 8, 2023)
This hotfix release addresses the following issues:
* [flutter/119881](https://github.com/flutter/flutter/issues/119881) - [Impeller] App performance decreases when using emulated dashed lines.
* [flutter/119245](https://github.com/flutter/flutter/issues/119245) - [Impeller] App crashes due to invalid textures when using impeller.
* [flutter/119489](https://github.com/flutter/flutter/issues/119489) - [Impeller] Text glyphs render incorrectly on different font weights
* [flutter/103847](https://github.com/flutter/flutter/issues/103847) - Fix animation jank on some iPhone models.
* [flutter/119593](https://github.com/flutter/flutter/issues/119593) - Localization files fail to generate when `FLUTTER_STORAGE_BASE_URL` is overridden.
* [flutter/119084](https://github.com/flutter/flutter/issues/119084) - When requesting to evaluate multiple expressions while debugging Flutter web apps, tooling fails before finishing operations.
* [flutter/119261](https://github.com/flutter/flutter/issues/119261) - Flutter tool crashes when attempting to update the artifact cache.
* [flutter/117420](https://github.com/flutter/flutter/issues/117420) - Ink ripple is rendered incorrectly inside of the `NavigationBar` widget when using Material 3.
* [dart/50622](https://github.com/dart-lang/sdk/issues/50622) - VM crashes when mixing the use of double and float calculations in debug/JIT configuration.
* [flutter/119220](https://github.com/flutter/flutter/issues/119220) - Compiler may crash when attempting to inline a method with lots of optional parameters with distinct default values.
* [dart/51087](https://github.com/dart-lang/sdk/issues/51087) - `part_of_different_library` error may be encountered when using `PackageBuildWorkspace`.

### [3.7.1](https://github.com/flutter/flutter/releases/tag/3.7.1) (Feb 1, 2023)
This hotfix release addresses the following issues:
* [flutter/116782](https://github.com/flutter/flutter/issues/116782) - Material 3 Navigation Drawer does not support scrolling or safe areas
* [flutter/119414](https://github.com/flutter/flutter/issues/119414) - ImageFilter in ListView causes wrong offset on Android and iOS
* [flutter/119181](https://github.com/flutter/flutter/issues/119181) - CastError when running `flutter pub get`
* [flutter/118613](https://github.com/flutter/flutter/issues/118613) - [Impeller] Fonts are blurry when rendering on iOS
* [flutter/118945](https://github.com/flutter/flutter/issues/118945) - [Impeller] Objects with large stroke width not drawn correctly on iOS
* [flutter/117428](https://github.com/flutter/flutter/issues/117428) - [Impeller] Text is transformed incorrectly on iOS
* [flutter/119072](https://github.com/flutter/flutter/issues/119072) - [Impeller] Draw calls could be improperly culled
* [flutter/118847](https://github.com/flutter/flutter/issues/118847) - [Impeller] Float samplers can get re-ordered compared to SkSL
* [flutter/119014](https://github.com/flutter/flutter/issues/119014) - Replace iPhone 6s with iPhone 11 as flutter test devices

### [3.7.0](https://github.com/flutter/flutter/releases/tag/3.7.0) (Jan 24, 2023)
Initial stable release.

## Flutter 3.3 Changes

### [3.3.10](https://github.com/flutter/flutter/releases/tag/3.3.10) (Dec 16, 2022)
This hotfix release addresses the following issues:
* [flutter/113314](https://github.com/flutter/flutter/issues/113314) - Glitches appear when scrolling on Android TV devices.
* [flutter/80401](https://github.com/flutter/flutter/issues/80401) - Some widgets are not visible when nested inside of `ClipRRect` in CanvasKit mode when using Flutter web on Safari.

### [3.3.9](https://github.com/flutter/flutter/releases/tag/3.3.9) (Nov 23, 2022)
This hotfix release addresses the following issues:
* [dart/50199](https://github.com/dart-lang/sdk/issues/50119) - fix error when using private variable setters in mixins on dart web.
* [dart/50392](https://github.com/dart-lang/sdk/issues/50392) - Type parameter nullability performs incorrectly in factory constructors.

### [3.3.8](https://github.com/flutter/flutter/releases/tag/3.3.8) (Nov 09, 2022)
This hotfix release addresses the following issues:
* [flutter/113973](https://github.com/flutter/flutter/issues/113973) - Fix null safety issue in TextFormField when Android devices pass no data
* [flutter/109632](https://github.com/flutter/flutter/issues/109632) - Fix type conversion in TextInput that didn’t allow num types

### [3.3.7](https://github.com/flutter/flutter/releases/tag/3.3.6) (Nov 2, 2022)
This hotfix release addresses the following issues:
* [flutter/113550](https://github.com/flutter/flutter/issues/113550) - Fix unnecessary null safe exceptions in input decorators on Android
* [flutter/100522](https://github.com/flutter/flutter/issues/100522) - Speculative fix for iOS screen flickering

### [3.3.6](https://github.com/flutter/flutter/releases/tag/3.3.6) (Oct 26, 2022)
This hotfix release addresses the following issues:
* [flutter/111255](https://github.com/flutter/flutter/issues/111255) - Using WebView leads to size error in platform_views since Flutter 3.3.0

### [3.3.5](https://github.com/flutter/flutter/releases/tag/3.3.5) (Oct 19, 2022)
This hotfix release addresses the following issues:
* [flutter/113035](https://github.com/flutter/flutter/pull/113035) - Apps crash when `FadeInImage` switches from cached to uncached images.
* [flutter/112228](https://github.com/flutter/flutter/pull/112228) - Move documentation build and deployment to post-submit.
* [flutter/36807](https://github.com/flutter/engine/pull/36807) - Apps crash when combining emojis and Korean text.
* [flutter/112887](https://github.com/flutter/flutter/pull/112887) - When debugging web apps, erroneous errors are displayed.

### [3.3.4](https://github.com/flutter/flutter/releases/tag/3.3.4) (Oct 05, 2022)
This hotfix release addresses the following issues:
* [Flutter/36181](https://github.com/flutter/engine/pull/36181) - On Flutter desktop apps, pixel snapping performs incorrectly when using opacity layers at certain DPRs and screen sizes.
* [flutter/36491](https://github.com/flutter/engine/pull/36491) - On android devices with a refresh rate greater than 60hz, frames jump when scrolling.

### [3.3.3](https://github.com/flutter/flutter/releases/tag/3.3.3) (Sept 28, 2022)
This hotfix release addresses the following issues:
* [flutter/111475](https://github.com/flutter/flutter/issues/111475) - Signing errors on iOS pod bundle resources on Xcode 14 "Signing for "x" requires a development team."
* [flutter/110671](https://github.com/flutter/flutter/issues/110671) - App crashes on latest versions when AnimatedContainer / Container height is set to 0 and throws uncaught exception
* [flutter/107590](https://github.com/flutter/flutter/issues/107590) - Flutter tools ShaderCompilerException with exit code -1073740791.
* [flutter/110640](https://github.com/flutter/flutter/issues/110640) - Fatal crash with java.lang.AssertionError when selecting text in TextField.
* [dart/50075](https://github.com/dart-lang/sdk/issues/50075) - Security vulnerability: There is a auth bypass vulnerability in Dart SDK, specifically dart:uri core library, used to parse and validate URLs.
* [dart/50052](https://github.com/dart-lang/sdk/issues/50052) - Avoid CFE crash when input contains invalid super parameters usage.

### [3.3.2](https://github.com/flutter/flutter/releases/tag/3.3.2) (Sept 14, 2022)
This hotfix release addresses the following issues:
* [flutter/111411](https://github.com/flutter/flutter/issues/111411) - Package assets fail to load.
* [flutter/111296](https://github.com/flutter/flutter/issues/111296) - Custom embedders fail to build for 32 bit targets.
* [flutter/111274](https://github.com/flutter/flutter/issues/111274) - Android plugins crash when using platform view's Virtual Display fallback.
* [flutter/111231](https://github.com/flutter/flutter/issues/111231) - Text rendering is handled incorrectly.
* [dart/49923](https://github.com/dart-lang/sdk/issues/49923) - Incorrect type propagation when using `late` variables in catch blocks.

### [3.3.1](https://github.com/flutter/flutter/releases/tag/3.3.1) (Sept 7, 2022)
This hotfix release addresses the following issues:
* [flutter/110820](https://github.com/flutter/flutter/issues/110820) - Windows apps crash when accessibility is enabled on apps that use widgets with custom semantic actions.

### [3.3.0](https://github.com/flutter/flutter/releases/tag/3.3.0) (Aug 30, 2022)
Initial stable release.
## Flutter 3.0 Changes
### [3.0.5](https://github.com/flutter/flutter/releases/tag/3.0.5) (July 13, 2022)
This hotfix release addresses the following issues:
* [flutter/106601](https://github.com/flutter/flutter/issues/106601) - Flutter tool fails on visual studio on certain locales on Windows.
* [flutter/106510](https://github.com/flutter/flutter/issues/106510) - Flutter crashes on launch on ARM devices.
* [dart/49054](https://github.com/dart-lang/sdk/issues/49054) - Improves code completion for Flutter.
* [dart/49402](https://github.com/dart-lang/sdk/issues/49402) - Compiler crashes when using Finalizable parameters.
### [3.0.4](https://github.com/flutter/flutter/releases/tag/3.0.4) (July 1, 2022)
This hotfix release addresses the following issues:
* [flutter/105183](https://github.com/flutter/flutter/issues/105183) - Pointer compression on iOS causes OOM
* [flutter/103870](https://github.com/flutter/flutter/issues/103870) - Application crashes on system low memory events
* [flutter/105674](https://github.com/flutter/flutter/issues/105674) - Rendering artifacts from ImagedFiltered/ColorFiltered in animated views
### [3.0.3](https://github.com/flutter/flutter/releases/tag/3.0.3) (June 22, 2022)
This hotfix release addresses the following issues:
* [dart/49188](https://github.com/dart-lang/sdk/issues/49188) - Improve analysis of enums and switch.
* [dart/49075](https://github.com/dart-lang/sdk/issues/49075) - Fix compiler crash when initializing Finalizable objects.
### [3.0.2](https://github.com/flutter/flutter/releases/tag/3.0.2) (June 10, 2022)
This hotfix release addresses the following issues:
* [flutter/104785](https://github.com/flutter/flutter/issues/104785) - Flutter web apps show a black screen on Safari 13.
* [flutter/102451](https://github.com/flutter/flutter/issues/102451) - `flutter doctor` crashes for Windows users using Visual Studio 2022.
* [flutter/103846](https://github.com/flutter/flutter/issues/103846) - Unexpected line breaks occur when using new text renderer.
* [flutter/104569](https://github.com/flutter/flutter/pull/104569) - Ink Sparkle slows down applications using Material 3.
* [flutter/103404](https://github.com/flutter/flutter/issues/103404) - SliverReorderableList does not drag on Android devices.
* [flutter/103556](https://github.com/flutter/flutter/issues/103566) - Nested horizontal sliders in widgets with horizontal drag gestures do not work in Android applications.
 * [flutter/100375](https://github.com/flutter/flutter/issues/100375) - Build process fails when building Windows applications.
 * [dart/49027](https://github.com/dart-lang/sdk/issues/49027) - Code suggestion for initState/dispose/setState no longer work on intellij.
* [dart/3424](https://github.com/dart-lang/pub/issues/3424) - `dart pub login` fails when attempting to publish a package.
* [dart/49097](https://github.com/dart-lang/sdk/issues/49097) - `dart analyze` throws errors when using enhance Enums feature.
### [3.0.1](https://github.com/flutter/flutter/releases/tag/3.0.1) (May 19, 2022)
This hotfix release addresses the following issues:
 * [flutter/102947](https://github.com/flutter/flutter/issues/102947) - Radial gradients behave incorrectly when painting text.
### [3.0.0](https://github.com/flutter/flutter/releases/tag/3.0.0) (May 11, 2022)
Initial stable release.
## Flutter 2.10 Changes
### [2.10.5](https://github.com/flutter/flutter/releases/tag/2.10.5) (April 18, 2022)
This hotfix release addresses the following issues:
 * [flutter/101224](https://github.com/flutter/flutter/issues/101224) - Flutter web debugger fails when using chrome 100 or greater.
### [2.10.4](https://github.com/flutter/flutter/releases/tag/2.10.4) (March 28, 2022)
This hotfix release addresses the following issues:
 * [flutter/93871](https://github.com/flutter/flutter/issues/93871) - Custom embedders fail to build when using default sysroot (GCC 11).
 * [dart/48559](https://github.com/dart-lang/sdk/issues/48559) - Flutter web apps crash when using package:freezed.
### [2.10.3](https://github.com/flutter/flutter/releases/tag/2.10.3) (March 02, 2022)
This hotfix release addresses the following issues:
 * [flutter/98973](https://github.com/flutter/flutter/issues/98973) - Deadlock in application startup in profile/release mode.
 * [flutter/98739](https://github.com/flutter/flutter/issues/98739) - ios: Visual glitch when scrolling a list in a Scaffold that has a Material and Container as bottomNavigationBar.
 * [flutter/97086](https://github.com/flutter/flutter/issues/97086) - Windows: Fail to launch app in debug mode.
### [2.10.2](https://github.com/flutter/flutter/releases/tag/2.10.2) (February 18, 2022)
This hotfix release addresses the following issues:
 * [flutter/95211](https://github.com/flutter/flutter/issues/95211) - Transform animation with BackdropFilter is causing a crash.
 * [flutter/98155](https://github.com/flutter/flutter/issues/98155) - App crashes after upgrading to 2.10.x using webview + video_player plugin.
 * [flutter/98361](https://github.com/flutter/flutter/issues/98361) - Error in DL bounds calculations causes incorrect SVG rendering.
 * [flutter/97767](https://github.com/flutter/flutter/issues/97767) - New material icons are not properly rendered.
 * [flutter/95711](https://github.com/flutter/flutter/issues/95711) - Linux builds default to building GLFW.
### [2.10.1](https://github.com/flutter/flutter/releases/tag/2.10.1) (February 9, 2022)
This hotfix release addresses the following issues:
 * [flutter/94043](https://github.com/flutter/flutter/issues/94043) - Autofill does not work in `TextField`.
 * [flutter/96411](https://github.com/flutter/flutter/issues/96411) - Safari: Unable to enter text into `TextField`.
 * [flutter/96661](https://github.com/flutter/flutter/issues/96661) - Platform views throw fatal exception: Methods marked with @UiThread must be executed on the main thread.
 * [flutter/97103](https://github.com/flutter/flutter/issues/97103) - Images become corrupted when using CanvasKit.
 * [flutter/97679](https://github.com/flutter/flutter/issues/97679) - Don't remove overlay views when the rasterizer is being torn down.
 * [dart/48301](https://github.com/dart-lang/sdk/issues/48301) - Avoid speculative conversion in ffi Pointer.asTypedList.
### [2.10.0](https://github.com/flutter/flutter/releases/tag/2.10.0) (February 3, 2022)
Initial stable release.
## Flutter 2.8 Changes
### [2.8.1](https://github.com/flutter/flutter/releases/tag/2.8.1) (December 16, 2021)
This hotfix release addresses the following issues:
 * [flutter/94914](https://github.com/flutter/flutter/issues/94914) - Apps using `google_sign_in` or `google_maps` don't build in iOS Simulator on ARM macOS
 * [flutter/90783](https://github.com/flutter/flutter/issues/90783) - In rare circumstances, engine may crash during app termination on iOS and macOS
 * [dart/47914](https://github.com/dart-lang/sdk/issues/47914) - AOT compilation fails with error "Invalid argument(s): Missing canonical name for Reference"
 * [dart/47815](https://github.com/dart-lang/sdk/issues/47815) - Running `dart pub publish` with custom pub package server that has URL containing a path may fail.

### [2.8.0](https://github.com/flutter/flutter/releases/tag/2.8.0) (December 8, 2021)
Initial stable release.

## Flutter 2.5 Changes
### [2.5.3](https://github.com/flutter/flutter/releases/tag/2.5.3) (October 15, 2021)
This hotfix release addresses the following issues:
 * [dart/47321](https://github.com/dart-lang/sdk/issues/47321) - Fix a potential out-of-memory condition with analysis server plugins
 * [dart/47432](https://github.com/dart-lang/sdk/issues/47432) - Fix certificate loading on Windows when there are expired certificates
 * [flutter/83792](https://github.com/flutter/flutter/issues/83792) - Fix HTTPS issue related to: "HttpClient throws Invalid argument(s): Invalid internet address"

### [2.5.2]((https://github.com/flutter/flutter/releases/tag/2.5.2)) (September 30, 2021)
This hotfix release addresses the following issues:
 * [dart/47285](https://github.com/dart-lang/sdk/issues/47285) - Fix a regression to the performance of code completions
 * [dart/47316](https://github.com/dart-lang/sdk/issues/47316) - Dynamic tables in ELF files have invalid relocated addresses
 * [flutter/89912](https://github.com/flutter/flutter/issues/89912) - Building iOS app generates unnecessary Flutter.build folder

### [2.5.1]((https://github.com/flutter/flutter/releases/tag/2.5.1)) (September 17, 2021)
This hotfix release addresses the following issues:
 * [flutter/88767](https://github.com/flutter/flutter/issues/88767) - java.lang.SecurityException: Permission denial crash at launch
 * [flutter/88236](https://github.com/flutter/flutter/issues/88236) - null check exception during keyboard keypress
 * [flutter/88221](https://github.com/flutter/flutter/issues/88221) - Material routes delayed on push and pop
 * [flutter/84113](https://github.com/flutter/flutter/issues/84113) - HTTP exceptions talking to VM Service
 * [flutter/83632](https://github.com/flutter/flutter/issues/83632) - Scroll view velocity too high

### 2.5.0 (September 8, 2021)
Initial stable release.

## Flutter 2.2 Changes
### [2.2.3](https://github.com/flutter/flutter/pull/85719) (July 2, 2021)
This hotfix release addresses the following issues:
  * [flutter/84212](https://github.com/flutter/flutter/issues/84212) - Upgrading to 2.2.1 cause main.dart to crash
  * [flutter/83213](https://github.com/flutter/flutter/issues/83213) - TextFormField not responding to inputs on Android when typing on Microsoft SwiftKey
  * [flutter/82838](https://github.com/flutter/flutter/issues/82838) - Flutter Web failing to compile with "Undetermined Nullability"
  * [flutter/82874](https://github.com/flutter/flutter/issues/82874) - PopupMenuButton is broken after upgrade to Flutter 2.2.

### [2.2.2](https://github.com/flutter/flutter/pull/84364) (June 11, 2021)
This hotfix release addresses the following issues:
  *  [dart/46249](https://github.com/dart-lang/sdk/issues/46249) - Ensure start/stop file watching requests are run on the dart thread.
  *  [dart/46210](https://github.com/dart-lang/sdk/issues/46210) - Fix an analyze crash when analyzing against package:meta v1.4.0
  *  [dart/46173](https://github.com/dart-lang/sdk/issues/46173) - Merge a3767f7db86a85fcd6201e9357ad47b884002b66 to stable channel (2.13)
  *  [dart/46300](https://github.com/dart-lang/sdk/issues/46300) - Fix OOM VM test (`transferable_throws_oom_test` crashing after upgrade from Ubuntu 16)
  *  [dart/46298](https://github.com/dart-lang/sdk/issues/46298) - Ensure start/stop file watching requests are run on the Dart thread
  *  [flutter/83799](https://github.com/flutter/flutter/issues/83799) - Tool may crash if pub is missing from the artifact cache
  *  [flutter/83102](https://github.com/flutter/flutter/issues/83102) - Generated l10n file is missing ‘intl’ import with Flutter 2.2.0
  *  [flutter/83094](https://github.com/flutter/flutter/issues/83094) - Flutter AOT precompiler crash
  *  [flutter/82874](https://github.com/flutter/flutter/issues/82874) - PopupMenuButton is broken after upgrade to Flutter 2.2.

### [2.2.1](https://github.com/flutter/flutter/pull/83372) (May 27, 2021)
This hotfix release addresses the following issues:
 - [flutter/80978](https://github.com/flutter/flutter/issues/80978) - Error "Command PhaseScriptExecution failed with a nonzero exit code" when building on macOS
 - [dart/45990](https://github.com/dart-lang/sdk/issues/45990) - CastMap performs an invalid cast on 'remove', breaking shared_preferences plugin
 - [dart/45907](https://github.com/dart-lang/sdk/issues/45907) - DDC missing nullability information from recursive type hierarchies
 - [flutter/52106](https://github.com/flutter/flutter/issues/52106) - [Web] Accessibility focus border doesn’t follow when navigating through interactive elements with tab key
 - [flutter/82768](https://github.com/flutter/flutter/issues/82768) - [Web] svgClip memory leak in Canvaskit renderer

### 2.2.0 (May 18, 2021)
Initial stable release.

## Flutter 2.0 Changes
### [2.0.6](https://github.com/flutter/flutter/pull/81508) (April 29, 2021)
This hotfix release addresses the following issue:
 - [flutter/81326](https://github.com/flutter/flutter/issues/81326) - macOS binaries not codesigned

### [2.0.5](https://github.com/flutter/flutter/pull/80570) (April 16, 2021)
This hotfix release addresses the following issue:
 - [dart/45306](https://github.com/dart-lang/sdk/issues/45306) - Segmentation fault on specific code

### [2.0.4](https://github.com/flutter/flutter/pull/79486) (April 2, 2021)
This hotfix release addresses the following issues:
 - [flutter/78589](https://github.com/flutter/flutter/issues/78589) - Cocoapod transitive dependencies with bitcode fail to link against debug Flutter framework
 - [flutter/76122](https://github.com/flutter/flutter/issues/76122) - Adding a WidgetSpan widget causes web HTML renderer painting issue
 - [flutter/75280](https://github.com/flutter/flutter/issues/75280) - Dragging the "draggable" widget causes widget to freeze in the overlay layer on Web

### [2.0.3](https://github.com/flutter/flutter/pull/78489) (March 19, 2021)
This hotfix release addresses the following issues:
 - [flutter/75261](https://github.com/flutter/flutter/issues/75261) - Unable to deep link into Android app
 - [flutter/78167](https://github.com/flutter/flutter/issues/78167) - Flutter crash after going to version 2
 - [flutter/75677](https://github.com/flutter/flutter/issues/75677) - NoSuchMethodError: The method 'cancel' was called on null at AnsiSpinner.finish
 - [flutter/77419](https://github.com/flutter/flutter/pull/77419) - Fix Autovalidate enum references in fix data

### [2.0.2](https://github.com/flutter/flutter/pull/77850) (March 12, 2021)
This hotfix release addresses the following issues:
  - [flutter/77251](https://github.com/flutter/flutter/issues/77251) - Flutter may show multiple snackbars when Scaffold is nested
  - [flutter/75473](https://github.com/flutter/flutter/issues/75473) - CanvasKit throws error when using Path.from
  - [flutter/76597](https://github.com/flutter/flutter/issues/76597) - When multiple Flutter engines are active, destroying one engine causes crash
  - [flutter/75061](https://github.com/flutter/flutter/issues/75061) - '_initialButtons == kPrimaryButton': is not true
  - [flutter/77419](https://github.com/flutter/flutter/pull/77419) - Fix Autovalidate enum references in fix data
  - [dart/45214](https://github.com/dart-lang/sdk/issues/45214) - Bad state exception can occur when HTTPS connection attempt errors or is aborted
  - [dart/45140](https://github.com/dart-lang/sdk/issues/45140) - Uint8List reports type exception while using + operator in null safety mode

### [2.0.1](https://github.com/flutter/flutter/pull/77194) (March 5, 2021)
This hotfix release addresses the following issue:
  - [flutter/77173](https://github.com/flutter/flutter/issues/77173) - Building for macOS target fails when Flutter is installed from website

### 2.0.0 (March 3, 2021)
Initial stable release.

## Flutter 1.22 Changes
### [1.22.6](https://github.com/flutter/flutter/pull/74355) (Jan 25, 2021)
This hotfix release addresses the following issue:
  - [flutter/70895](https://github.com/flutter/flutter/issues/70895) - Build error when switching between dev/beta and stable branches.

### [1.22.5](https://github.com/flutter/flutter/pull/72079) (Dec 10, 2020)
This hotfix release addresses the following issue:
  - [flutter/70577](https://github.com/flutter/flutter/issues/70577) - Reliability regression in the camera plugin on iOS

### [1.22.4](https://github.com/flutter/flutter/pull/70327) (Nov 13, 2020)
This hotfix release addresses the following issues:
  - [flutter/43620](https://github.com/flutter/flutter/issues/43620) - Dart analyzer terminates during development
  - [flutter/58200](https://github.com/flutter/flutter/issues/58200) - Apple AppStore submission fails with error: “The bundle Runner.app/Frameworks/App.framework does not sue Infpport the minimum OS Version specified in the Info.plist”
  - [flutter/69722](https://github.com/flutter/flutter/issues/69722) - Setting a custom observatory port for debugging does not take effect
  - [flutter/66144](https://github.com/flutter/flutter/issues/66144) - Setting autoFillHint to text form field may cause focus issues
  - [flutter/69449](https://github.com/flutter/flutter/issues/69449) - Potential race condition in FlutterPlatformViewsController
  - [flutter/65133](https://github.com/flutter/flutter/issues/65133) - Support targeting physical iOS devices on Apple Silicon

### [1.22.3](https://github.com/flutter/flutter/pull/69234) (October 30, 2020)
This hotfix release addresses the following issues:
  - [flutter/67828](https://github.com/flutter/flutter/issues/67828) - Multiple taps required to delete text in some input fields.
  - [flutter/66108](https://github.com/flutter/flutter/issues/66108) - Reading Android clipboard may throw a security exception if it contains media

### [1.22.2](https://github.com/flutter/flutter/pull/68135)  (October 16, 2020)
This hotfix release addresses the following issues:
  - [flutter/67869](https://github.com/flutter/flutter/issues/67869) - Stylus tap gesture is improperly registered.
  - [flutter/67986](https://github.com/flutter/flutter/issues/67986) - Android Studio 4.1 not properly supported.
  - [flutter/67213](https://github.com/flutter/flutter/issues/67213) - Webviews in hybrid composition can cause a crash.
  - [flutter/67345](https://github.com/flutter/flutter/issues/67345) - VoiceOver accessibility issue with some pages.
  - [flutter/66764](https://github.com/flutter/flutter/issues/66764) - Native webviews may not be properly disposed of in hybrid composition.

### [1.22.1](https://github.com/flutter/flutter/pull/67552) (October 8, 2020)
This hotfix release addresses the following issues:
  - [flutter/66940](https://github.com/flutter/flutter/issues/66940) - autovalidate property inadvertently removed.
  - [flutter/66962](https://github.com/flutter/flutter/issues/66962) - The new --analyze-size flag crashes when used with --split-debug-info
  - [flutter/66908](https://github.com/flutter/flutter/issues/66908) - Flutter Activity causing exceptions in some Android versions.
  - [flutter/66647](https://github.com/flutter/flutter/issues/66647) - Layout modifications performed by background threads causes exceptions on IOS14.

### 1.22.0 (October 1, 2020)
Initial stable release.

## Flutter 1.20 Changes
### [1.20.4](https://github.com/flutter/flutter/pull/65787) (September 15, 2020)
This hotfix release addresses the following issues:
  - [flutter/64045](https://github.com/flutter/flutter/issues/64045) - Cannot deploy to physical device running iOS 14

### [1.20.3](https://github.com/flutter/flutter/pull/64984) (September 2, 2020)
This hotfix release addresses the following issues:
  - [flutter/63876](https://github.com/flutter/flutter/issues/63876) - Performance regression for Image animation.
  - [flutter/64228](https://github.com/flutter/flutter/issues/64228) - WebView may freeze in release mode on iOS.
  - [flutter/64414](https://github.com/flutter/flutter/issues/64414) - Task switching may freeze on some Android versions.
  - [flutter/63560](https://github.com/flutter/flutter/issues/63560) - Building AARs may cause a stack overflow.
  - [flutter/57210](https://github.com/flutter/flutter/issues/57210) - Certain assets may cause issues with iOS builds.
  - [flutter/63590](https://github.com/flutter/flutter/issues/63590) - Passing null values from functions run via Isolates throws an exception.
  - [flutter/63427](https://github.com/flutter/flutter/issues/63427) - Wrong hour/minute order in timePicker in RTL mode.

### [1.20.2](https://github.com/flutter/flutter/pull/63591) (August 13, 2020)
This hotfix release addresses the following issues:
  - [flutter/63038](https://github.com/flutter/flutter/issues/63038) - Crash due to serialization of generic DartType (UnknownType)
  - [flutter/46167](https://github.com/flutter/flutter/issues/46167) - iOS platform view cancels gesture while a new clip layer is added during the gesture
  - [flutter/62198](https://github.com/flutter/flutter/issues/62198) - SliverList throws Exception when first item is SizedBox.shrink()
  - [flutter/59029](https://github.com/flutter/flutter/issues/59029) - build ios --release can crash with ArgumentError: Invalid argument(s)
  - [flutter/62775](https://github.com/flutter/flutter/issues/62775) - TimePicker is not correct in RTL (right-to-left) languages
  - [flutter/55535](https://github.com/flutter/flutter/issues/55535) - New DatePicker widget is not fully  localized
  - [flutter/63373](https://github.com/flutter/flutter/issues/63373) - Double date separators appearing in DatePicker, preventing date selection
  - [flutter/63176](https://github.com/flutter/flutter/issues/63176) -  App.framework path in Podfile incorrect

### [1.20.1](https://github.com/flutter/flutter/pull/62990) (August 6, 2020)
This hotfix release addresses the following issues:
  - [flutter/60215](https://github.com/flutter/flutter/issues/60215) - Creating an Android-only plug-in creates a no-op iOS folder.

### 1.20.0 (August 5, 2020)
Initial stable release.

## Flutter 1.17 Changes
### [1.17.5](https://github.com/flutter/flutter/pull/60611) (June 30, 2020)
This hotfix release addresses the following issues:
  - [flutter-intellij/4642]https://github.com/flutter/flutter-intellij/issues/4642  - Intellij/Android Studio plugins fail to show connected Android devices.

### [1.17.4](https://github.com/flutter/flutter/pull/59695) (June 18, 2020)
This hotfix release addresses the following issues:
  - [flutter/56826](https://github.com/flutter/flutter/issues/56826)  - xcdevice polling may use all free hard drive space

### [1.17.3](https://github.com/flutter/flutter/pull/58646) (June 4, 2020)
This hotfix release addresses the following issues:
 - [flutter/54420](https://github.com/flutter/flutter/issues/54420)  - Exhausted heap space can cause machine to freeze

### [1.17.2](https://github.com/flutter/flutter/pull/58050) (May 28, 2020)
This hotfix release addresses the following issues:
 - [flutter/57326](https://github.com/flutter/flutter/issues/57326)  - CupertinoSegmentedControl does not always respond to selections
 - [flutter/56898](https://github.com/flutter/flutter/issues/56898) - DropdownButtonFormField is not re-rendered after value is changed programmatically
 - [flutter/56853](https://github.com/flutter/flutter/issues/56853) - Incorrect git error may be presented when flutter upgrade fails
 - [flutter/55552](https://github.com/flutter/flutter/issues/55552) - Hot reload may fail after a hot restart
 - [flutter/56507](https://github.com/flutter/flutter/issues/56507) - iOS builds may fail with “The path does not exist” error message

### [1.17.1](https://github.com/flutter/flutter/pull/57052) (May 13, 2020)
This hotfix release addresses the following issues:
 - [flutter/26345](https://github.com/flutter/flutter/issues/26345) - Updating `AndroidView` layer tree causes crash on Xiaomi and Moto devices
 - [flutter/56567](https://github.com/flutter/flutter/issues/56567) - Xcode legacy build system causes build failures on iOS
 - [flutter/56473](https://github.com/flutter/flutter/issues/56473) - Build `--tree-shake-icons` build option crashes computer
 - [flutter/56688](https://github.com/flutter/flutter/issues/56688) - Regression in `Navigator.pushAndRemoveUntil`
 - [flutter/56479](https://github.com/flutter/flutter/issues/56479) - Crash while getting static type context for signature shaking

### 1.17.0 (May 5, 2020)
Initial stable release.

## Flutter 1.12 Changes
### Hotfix.9 (April 1, 2020)
This hotfix release addresses the following issues:
 - [flutter/47819](https://github.com/flutter/flutter/issues/47819) - Crashes on ARMv8 Android devices
 - [flutter/49185](https://github.com/flutter/flutter/issues/49185) - Issues using Flutter 1.12 with Linux 5.5
 - [flutter/51712](https://github.com/flutter/flutter/issues/51712) - fixes for licensing from Android sdkmanager tool not being found

### [Hotfix.8](https://github.com/flutter/flutter/pull/50591) (February 11, 2020)
This hotfix release addresses the following issues:
 - [flutter/50066](https://github.com/flutter/flutter/issues/50066) - binaries unsigned in last hotfix
 - [flutter/49787](https://github.com/flutter/flutter/issues/49787) - in a previous hotfix, we inadvertently broke Xcode 10 support. Reverting this change would have caused other problems (and users would still have to upgrade their Xcode with the next stable release), we decided to increase our minimum supported Xcode version. Please see the linked issue for more context on this decision.
 - [flutter/45732](https://github.com/flutter/flutter/issues/45732) - Android log reader fix
 - [flutter/47609](https://github.com/flutter/flutter/issues/47609) - Android log reader fix

### [Hotfix.7](https://github.com/flutter/flutter/pull/49437) (January 26, 2020)
This hotfix release addresses the following issues:
- [flutter/47164](https://github.com/flutter/flutter/issues/47164) - blackscreen / crash on certain Huawei devices
- [flutter/47804](https://github.com/flutter/flutter/issues/47804) - Flutter engine crashes on some Android devices due to "Failed to setup Skia Gr context"
- [flutter/46172](https://github.com/flutter/flutter/issues/46172) - reportFullyDrawn causes crash on Android KitKat

### Hotfix.5 (December 11, 2019)
Initial stable release.
