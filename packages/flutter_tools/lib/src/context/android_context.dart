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
    required this.androidSdk,
    required AndroidStudio? Function() androidStudio,
    required this.gradleUtils,
    required Java? Function() java,
  }) : _androidStudio = androidStudio,
       _java = java;

  /// Discovers, validates, and manages the local Android SDK and platform tools.
  final AndroidSdk? androidSdk;

  /// Discovers and inspects local Android Studio installations and embedded JDK paths.
  late final AndroidStudio? androidStudio = _androidStudio();

  /// Utility helpers for interacting with Gradle builds and resolving project configs.
  final GradleUtils gradleUtils;

  /// Discovers and validates the active Java Development Kit (JDK) binary.
  late final Java? java = _java();

  final AndroidStudio? Function() _androidStudio;
  final Java? Function() _java;
}
