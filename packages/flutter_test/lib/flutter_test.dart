// Copyright 2015 The Chromium Authors. All rights reserved.
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
/// Future<void> main(FutureOr<void> testMain());
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
library flutter_test;

export 'dart:async' show Future;

export 'src/accessibility.dart';
export 'src/all_elements.dart';
export 'src/binding.dart';
export 'src/controller.dart';
export 'src/finders.dart';
export 'src/goldens.dart';
export 'src/matchers.dart';
export 'src/nonconst.dart';
export 'src/stack_manipulation.dart';
export 'src/test_async_utils.dart';
export 'src/test_exception_reporter.dart';
export 'src/test_pointer.dart';
export 'src/test_text_input.dart';
export 'src/test_vsync.dart';
export 'src/widget_tester.dart';
