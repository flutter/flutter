// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../build_system/build_system.dart';
library;

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/gradle_utils.dart';
import '../android/java.dart';

/// Provides lazy access to the configured [AndroidSdk].
///
/// Both [AndroidContext] and the build system [Environment] implement this
/// interface so callers such as native assets targets can defer Android SDK
/// lookup until an Android toolchain is needed.
abstract interface class AndroidSdkProvider {
  /// The configured [AndroidSdk], or `null` if no Android SDK is available.
  AndroidSdk? get androidSdk;
}

/// Holds Android-specific dependencies.
class AndroidContext implements AndroidSdkProvider {
  AndroidContext({
    required this.androidSdkBuilder,
    required this.androidStudioBuilder,
    required this.gradleUtilsBuilder,
    required this.javaBuilder,
  });

  /// Discovers, validates, and manages the local Android SDK and platform tools.
  @override
  late final AndroidSdk? androidSdk = androidSdkBuilder();

  /// Discovers and inspects local Android Studio installations and embedded JDK paths.
  late final AndroidStudio? androidStudio = androidStudioBuilder();

  /// Utility helpers for interacting with Gradle builds and resolving project configs.
  late final GradleUtils gradleUtils = gradleUtilsBuilder();

  /// Discovers and validates the active Java Development Kit (JDK) binary.
  late final Java? java = javaBuilder();

  final AndroidSdk? Function() androidSdkBuilder;
  final AndroidStudio? Function() androidStudioBuilder;
  final GradleUtils Function() gradleUtilsBuilder;
  final Java? Function() javaBuilder;
}
