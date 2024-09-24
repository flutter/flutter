// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'platform.dart';
library;

/// A constant that is true if the application was compiled in release mode.
///
/// More specifically, this is a constant that is true if the application was
/// compiled in Dart with the '-Ddart.vm.product=true' flag.
///
/// Since this is a const value, it can be used to indicate to the compiler that
/// a particular block of code will not be executed in release mode, and hence
/// can be removed.
///
/// Generally it is better to use [kDebugMode] or `assert` to gate code, since
/// using [kReleaseMode] will introduce differences between release and profile
/// builds, which makes performance testing less representative.
///
/// See also:
///
///  * [kDebugMode], which is true in debug builds.
///  * [kProfileMode], which is true in profile builds.
const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// A constant that is true if the application was compiled in profile mode.
///
/// More specifically, this is a constant that is true if the application was
/// compiled in Dart with the '-Ddart.vm.profile=true' flag.
///
/// Since this is a const value, it can be used to indicate to the compiler that
/// a particular block of code will not be executed in profile mode, an hence
/// can be removed.
///
/// See also:
///
///  * [kDebugMode], which is true in debug builds.
///  * [kReleaseMode], which is true in release builds.
const bool kProfileMode = bool.fromEnvironment('dart.vm.profile');

/// A constant that is true if the application was compiled in debug mode.
///
/// More specifically, this is a constant that is true if the application was
/// not compiled with '-Ddart.vm.product=true' and '-Ddart.vm.profile=true'.
///
/// Since this is a const value, it can be used to indicate to the compiler that
/// a particular block of code will not be executed in debug mode, and hence
/// can be removed.
///
/// An alternative strategy is to use asserts, as in:
///
/// ```dart
/// assert(() {
///   // ...debug-only code here...
///   return true;
/// }());
/// ```
///
/// See also:
///
///  * [kReleaseMode], which is true in release builds.
///  * [kProfileMode], which is true in profile builds.
const bool kDebugMode = !kReleaseMode && !kProfileMode;

/// The epsilon of tolerable double precision error.
///
/// This is used in various places in the framework to allow for floating point
/// precision loss in calculations. Differences below this threshold are safe to
/// disregard.
const double precisionErrorTolerance = 1e-10;

/// A constant that is true if the application was compiled to run on the web.
///
/// See also:
///
/// * [defaultTargetPlatform], which is used by themes to find out which
///   platform the application is running on (or, in the case of a web app,
///   which platform the application's browser is running in). Can be overridden
///   in tests with [debugDefaultTargetPlatformOverride].
/// * [dart:io.Platform], a way to find out the browser's platform that is not
///   overridable in tests.
const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

/// A constant that is true if the application was compiled to WebAssembly.
///
/// See also:
///
/// * [defaultTargetPlatform], which is used by themes to find out which
///   platform the application is running on (or, in the case of a web app,
///   which platform the application's browser is running in). Can be overridden
///   in tests with [debugDefaultTargetPlatformOverride].
/// * [dart:io.Platform], a way to find out the browser's platform that is not
///   overridable in tests.
const bool kIsWasm = bool.fromEnvironment('dart.tool.dart2wasm');
