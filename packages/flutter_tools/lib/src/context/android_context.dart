// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/gradle_utils.dart';
import '../android/java.dart';

/// Holds Android-specific dependencies.
class AndroidContext {
  /// Creates an instance of [AndroidContext] with the required dependencies.
  AndroidContext({
    required this.androidSdk,
    required this.androidStudio,
    required this.gradleUtils,
    required this.java,
  });

  /// Discovers, validates, and manages the local Android SDK and platform tools.
  final AndroidSdk? androidSdk;

  /// Discovers and inspects local Android Studio installations and embedded JDK paths.
  final AndroidStudio? androidStudio;

  /// Utility helpers for interacting with Gradle builds and resolving project configs.
  final GradleUtils gradleUtils;

  /// Discovers and validates the active Java Development Kit (JDK) binary.
  final Java? java;
}
