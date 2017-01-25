// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'platform_messages.dart';

const String _kChannelName = 'flutter/platform';

/// Returns commonly used locations on the filesystem.
class PathProvider {
  PathProvider._();

  /// Path to the temporary directory on the device.
  ///
  /// Files in this directory may be cleared at any time. This does *not* return
  /// a new temporary directory. Instead, the caller is responsible for creating
  /// (and cleaning up) files or directories within this directory. This
  /// directory is scoped to the calling application.
  ///
  /// On iOS, this uses the `NSTemporaryDirectory` API.
  ///
  /// On Android, this uses the `getCacheDir` API on the context.
  static Future<Directory> getTemporaryDirectory() async {
    Map<String, dynamic> result = await PlatformMessages.invokeMethod(
        _kChannelName, 'PathProvider.getTemporaryDirectory');
    if (result == null)
      return null;
    return new Directory(result['path']);
  }

  /// Path to a directory where the application may place files that are private
  /// to the application and will only be cleared when the application itself
  /// is deleted.
  ///
  /// On iOS, this uses the `NSDocumentsDirectory` API.
  ///
  /// On Android, this returns the AppData directory.
  static Future<Directory> getApplicationDocumentsDirectory() async {
    Map<String, dynamic> result = await PlatformMessages.invokeMethod(
        _kChannelName, 'PathProvider.getApplicationDocumentsDirectory');
    if (result == null)
      return null;
    return new Directory(result['path']);
  }
}
