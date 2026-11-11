// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/gradle_utils.dart';
import '../android/java.dart';

/// Holds Android-specific dependencies.
class AndroidContext {
  AndroidContext({
    required this._androidSdkBuilder,
    required this._androidStudioBuilder,
    required this._gradleUtilsBuilder,
    required this._javaBuilder,
  });

  /// Discovers, validates, and manages the local Android SDK and platform tools.
  late final AndroidSdk? androidSdk = _androidSdkBuilder();

  /// Discovers and inspects local Android Studio installations and embedded JDK paths.
  late final AndroidStudio? androidStudio = _androidStudioBuilder();

  /// Utility helpers for interacting with Gradle builds and resolving project configs.
  late final GradleUtils gradleUtils = _gradleUtilsBuilder();

  /// Discovers and validates the active Java Development Kit (JDK) binary.
  late final Java? java = _javaBuilder();

  final AndroidSdk? Function() _androidSdkBuilder;
  final AndroidStudio? Function() _androidStudioBuilder;
  final GradleUtils Function() _gradleUtilsBuilder;
  final Java? Function() _javaBuilder;
}
