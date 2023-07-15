// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'assertions.dart';
import 'platform.dart' as platform;

export 'platform.dart' show TargetPlatform;

/// The dart:io implementation of [platform.defaultTargetPlatform].
platform.TargetPlatform get defaultTargetPlatform {
  platform.TargetPlatform? result;
  if (Platform.isAndroid) {
    result = platform.TargetPlatform.android;
  } else if (Platform.isIOS) {
    result = platform.TargetPlatform.iOS;
  } else if (Platform.isFuchsia) {
    result = platform.TargetPlatform.fuchsia;
  } else if (Platform.isLinux) {
    result = platform.TargetPlatform.linux;
  } else if (Platform.isMacOS) {
    result = platform.TargetPlatform.macOS;
  } else if (Platform.isWindows) {
    result = platform.TargetPlatform.windows;
  }
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      result = platform.TargetPlatform.android;
    }
    return true;
  }());
  if (platform.debugDefaultTargetPlatformOverride != null) {
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
