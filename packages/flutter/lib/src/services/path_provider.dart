// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:sky_services/flutter/platform/path_provider.mojom.dart' as mojom;

import 'shell.dart';

mojom.PathProviderProxy _initPathProviderProxy() {
  mojom.PathProviderProxy proxy = new mojom.PathProviderProxy.unbound();
  shell.connectToService('mojo:flutter_platform', proxy);
  return proxy;
}

final mojom.PathProviderProxy _pathProviderProxy = _initPathProviderProxy();

/// Returns commonly used locations on the filesystem.
class PathProvider {
  PathProvider._();

  /// Path to the temporary directory on the device. Files in this directory
  /// may be cleared at any time. This does *not* return a new temporary
  /// directory. Instead, the caller is responsible for creating
  /// (and cleaning up) files or directories within this directory. This
  /// directory is scoped to the calling application.
  ///
  /// Examples:
  ///
  ///  * _iOS_: `NSTemporaryDirectory()`
  ///  * _Android_: `getCacheDir()` on the context.
  static Future<Directory> getTemporaryDirectory() async {
    return new Directory((await _pathProviderProxy.ptr.temporaryDirectory()).path);
  }

  /// Path to a directory where the application may place files that are private
  /// to the application and will only be cleared when the application itself
  /// is deleted.
  ///
  /// Examples:
  ///
  ///  * _iOS_: `NSDocumentsDirectory`
  ///  * _Android_: The AppData directory.
  static Future<Directory> getApplicationDocumentsDirectory() async {
    return new Directory((await _pathProviderProxy.ptr.applicationDocumentsDirectory()).path);
  }
}
