// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'assertions.dart';

/// The platform that user interaction should adapt to target.
enum TargetPlatform {
  /// Android: <https://www.android.com/>
  android,

  /// iOS: <http://www.apple.com/ios/>
  iOS,
}

/// The [TargetPlatform] that matches the platform on which the framework is currently executing.
TargetPlatform get defaultTargetPlatform {
  if (Platform.isIOS || Platform.isMacOS)
    return TargetPlatform.iOS;
  if (Platform.isAndroid || Platform.isLinux)
    return TargetPlatform.android;
  throw new FlutterError(
    'Unknown platform\n'
    '${Platform.operatingSystem} was not recognized as a target platform. '
    'Consider updating the list of TargetPlatforms to include this platform.'
  );
}
