// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Testing library for flutter, built on top of `package:test`.
///
/// ## Test Configuration
///
/// The testing library exposes a few constructs by which projects may configure
/// their tests.
///
/// ### Per test or per file
///
/// Due to its use of `package:test` as a foundation, the testing library
/// allows for tests to be initialized using the existing constructs found in
/// `package:test`. These include the [setUp] and [setUpAll] methods.
///
/// ### Per directory hierarchy
///
/// In addition to the constructs provided by `package:test`, this library
/// supports the configuration of tests at the directory level.
///
/// Before a test file is executed, the Flutter test framework will scan up the
/// directory hierarchy, starting from the directory in which the test file
/// resides, looking for a file named `flutter_test_config.dart`. If it finds
/// such a configuration file, the file will be assumed to have a `main` method
/// with the following signature:
///
/// ```dart
/// Future<void> testExecutable(FutureOr<void> Function() testMain) async { }
/// ```
///
/// The test framework will execute that method and pass it the `main()` method
/// of the test. It is then the responsibility of the configuration file's
/// `main()` method to invoke the test's `main()` method.
///
/// After the test framework finds a configuration file, it will stop scanning
/// the directory hierarchy. In other words, the test configuration file that
/// lives closest to the test file will be selected, and all other test
/// configuration files will be ignored. Likewise, it will stop scanning the
/// directory hierarchy when it finds a `pubspec.yaml`, since that signals the
/// root of the project.
///
/// If no configuration file is located, the test will be executed like normal.
///
/// See also:
///
///  * [WidgetController.hitTestWarningShouldBeFatal], which can be set
///    in a `flutter_test_config.dart` file to turn warnings printed by
///    [WidgetTester.tap] and similar APIs into fatal errors.
///  * [debugCheckIntrinsicSizes], which can be set in a
///    `flutter_test_config.dart` file to enable deeper [RenderBox]
///    tests of the intrinsic APIs automatically while laying out widgets.
///
/// @docImport 'package:flutter/rendering.dart';
///
/// @docImport 'src/controller.dart';
/// @docImport 'src/test_compat.dart';
/// @docImport 'src/widget_tester.dart';
library;

export 'dart:async' show Future;

export 'src/_goldens_io.dart' if (dart.library.js_interop) 'src/_goldens_web.dart';
export 'src/_matchers_io.dart' if (dart.library.js_interop) 'src/_matchers_web.dart';
export 'src/_test_selector_io.dart' if (dart.library.js_interop) 'src/_test_selector_web.dart';
export 'src/accessibility.dart';
export 'src/animation_sheet.dart';
export 'src/binding.dart';
export 'src/controller.dart';
export 'src/deprecated.dart';
export 'src/event_simulation.dart';
export 'src/finders.dart';
export 'src/frame_timing_summarizer.dart';
export 'src/goldens.dart';
export 'src/image.dart';
export 'src/matchers.dart';
export 'src/mock_canvas.dart';
export 'src/mock_event_channel.dart';
export 'src/nonconst.dart';
export 'src/platform.dart';
export 'src/recording_canvas.dart';
export 'src/restoration.dart';
export 'src/stack_manipulation.dart';
export 'src/test_async_utils.dart';
export 'src/test_compat.dart';
export 'src/test_default_binary_messenger.dart';
export 'src/test_exception_reporter.dart';
export 'src/test_pointer.dart';
export 'src/test_text_input.dart';
export 'src/test_vsync.dart';
export 'src/tree_traversal.dart';
export 'src/widget_tester.dart';
export 'src/window.dart';
