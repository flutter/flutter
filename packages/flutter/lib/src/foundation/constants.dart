// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A constant that is true if the application was compiled in release mode.
///
/// More specifically, this is a constant that is true if the application was
/// compiled in Dart with the '-Dflutter.buildMode.release=true' flag, which the
/// `flutter` tool does.
const bool kReleaseMode = bool.fromEnvironment('flutter.buildMode.release', defaultValue: false);

/// A constant that is true if the application was compiled in profile mode.
///
/// More specifically, this is a constant that is true if the application was
/// compiled in Dart with the '-Dflutter.buildMode.profile=true' flag, which the
/// `flutter` tool does.
///
/// This flag is useful for indicating code blocks that should be removed by
/// tree shaking in release mode.
const bool kProfileMode = bool.fromEnvironment('flutter.buildMode.profile', defaultValue: false);

/// A constant that is true if the application was compiled in debug mode.
///
/// More specifically, this is a constant that is true if the application was
/// compiled in Dart with the '-Dflutter.buildMode.debug=true' flag, which the
/// `flutter` tool does.
///
/// This flag is useful for indicating code blocks that should be removed by
/// tree shaking in release mode.
const bool kDebugMode = bool.fromEnvironment('flutter.buildMode.debug', defaultValue: false);
