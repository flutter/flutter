// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Do not import this file in production applications or packages published
// to pub.dev. Flutter will make breaking changes to this file, even in patch
// versions.
//
// All APIs in this file must be private or must:
//
// 1. Have the `@internal` attribute.
// 2. Throw an `UnsupportedError` if `isWindowingEnabled`
//    is `false`.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'dart:io';

import 'package:flutter/foundation.dart';

import '_window.dart';
import '_window_linux.dart';
import '_window_macos.dart';
import '_window_win32.dart';

/// Creates a default [WindowingOwner] for the current platform.
///
/// Returns null if windowing is not supported on the current platform.
/// Only supported on desktop platforms.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
WindowingOwner? createDefaultOwner() {
  if (Platform.isWindows) {
    return WindowingOwnerWin32();
  } else if (Platform.isLinux) {
    return WindowingOwnerLinux();
  } else if (Platform.isMacOS) {
    return WindowingOwnerMacOS();
  } else {
    return null;
  }
}
