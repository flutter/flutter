// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_services/platform/path_provider.dart' as mojom;

import 'shell.dart';

mojom.PathProviderProxy _initPathProviderProxy() {
  return shell.connectToApplicationService('mojo:flutter_platform', mojom.PathProvider.connectToService);
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
  static Future<Directory> getTemporaryDirectory() {
    Completer<Directory> completer = new Completer<Directory>();
    _pathProviderProxy.temporaryDirectory((String path) {
      completer.complete(new Directory(path));
    });
    return completer.future;
  }

  /// Path to a directory where the application may place files that are private
  /// to the application and will only be cleared when the application itself
  /// is deleted.
  ///
  /// Examples:
  ///
  ///  * _iOS_: `NSDocumentsDirectory`
  ///  * _Android_: The AppData directory.
  static Future<Directory> getApplicationDocumentsDirectory() {
    Completer<Directory> completer = new Completer<Directory>();
    _pathProviderProxy.applicationDocumentsDirectory((String path) {
      completer.complete(new Directory(path));
    });
    return completer.future;
  }
}
