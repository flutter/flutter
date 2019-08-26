// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'platform.dart' as platform;

/// The dart:html implementation of [platform.resolvedExecutable].
String get resolvedExecutable => 'browser';

/// The dart:html implementation of [platform.pathSeparator].
String get pathSeparator => '/';

/// The dart:html implementation of [platform.currentHostPlatform].
platform.HostPlatform get currentHostPlatform {
  return platform.HostPlatform.browser;
}

/// The dart:html implementation of [platform.defaultTargetPlatform].
platform.TargetPlatform get defaultTargetPlatform {
  // To getter a better guess at the targetPlatform we need to be able to
  // reference the window, but that won't be availible until we fix the
  // platforms configuration for Flutter.
  platform.TargetPlatform result = platform.TargetPlatform.android;
  if (platform.debugDefaultTargetPlatformOverride != null)
    result = platform.debugDefaultTargetPlatformOverride;
  return result;
}
