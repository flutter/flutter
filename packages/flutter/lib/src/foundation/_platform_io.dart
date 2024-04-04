// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'assertions.dart';
import 'constants.dart';
import 'platform.dart' as platform;

export 'platform.dart' show TargetPlatform;

/// The dart:io implementation of [platform.defaultTargetPlatform].
@pragma('vm:platform-const-if', !kDebugMode)
platform.TargetPlatform get defaultTargetPlatform {
  platform.TargetPlatform? result = switch (Platform.operatingSystem) {
    'android' => platform.TargetPlatform.android,
    'ios'     => platform.TargetPlatform.iOS,
    'fuchsia' => platform.TargetPlatform.fuchsia,
    'linux'   => platform.TargetPlatform.linux,
    'macos'   => platform.TargetPlatform.macOS,
    'windows' => platform.TargetPlatform.windows,
    _ => null,
  };
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      result = platform.TargetPlatform.android;
    }
    return true;
  }());
  if (kDebugMode && platform.debugDefaultTargetPlatformOverride != null) {
    result = platform.debugDefaultTargetPlatformOverride;
  }
  if (result == null) {
    throw FlutterError(
      'Unknown platform.\n'
      '${Platform.operatingSystem} was not recognized as a target platform. '
      'Consider updating the list of TargetPlatforms to include this platform.',
    );
  }
  return result!;
}
