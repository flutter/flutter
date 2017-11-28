// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'assertions.dart';

/// The platform that user interaction should adapt to target.
///
/// The [defaultTargetPlatform] getter returns the current platform.
enum TargetPlatform {
  /// Android: <https://www.android.com/>
  android,

  /// Fuchsia: <https://fuchsia.googlesource.com/>
  fuchsia,

  /// iOS: <http://www.apple.com/ios/>
  iOS,
}

/// The [TargetPlatform] that matches the platform on which the framework is
/// currently executing.
///
/// In a test environment, the platform returned is [TargetPlatform.android]
/// regardless of the host platform. (Android was chosen because the tests were
/// originally written assuming Android-like behavior, and we added platform
/// adaptations for iOS later). Tests can check iOS behavior by using the
/// platform override APIs (such as [ThemeData.platform] in the material
/// library) or by setting [debugDefaultTargetPlatformOverride]. The value
/// can only be explicitly set in debug mode.
TargetPlatform get defaultTargetPlatform {
  TargetPlatform result;
  if (Platform.isIOS || Platform.isMacOS) {
    result = TargetPlatform.iOS;
  } else if (Platform.isAndroid || Platform.isLinux) {
    result = TargetPlatform.android;
  } else if (Platform.operatingSystem == 'fuchsia') {
    result = TargetPlatform.fuchsia;
  }
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST'))
      result = TargetPlatform.android;
    if (debugDefaultTargetPlatformOverride != null)
      result = debugDefaultTargetPlatformOverride;
    return true;
  }());
  if (result == null) {
    throw new FlutterError(
      'Unknown platform.\n'
      '${Platform.operatingSystem} was not recognized as a target platform. '
      'Consider updating the list of TargetPlatforms to include this platform.'
    );
  }
  return result;
}
/// Override the [defaultTargetPlatform].
///
/// Setting this to null returns the [defaultTargetPlatform] to its original
/// value (based on the actual current platform).
///
/// This setter is only available intended for debugging purposes. To change the
/// target platform in release builds, use the platform override APIs (such as
/// [ThemeData.platform] in the material library).
TargetPlatform debugDefaultTargetPlatformOverride;
