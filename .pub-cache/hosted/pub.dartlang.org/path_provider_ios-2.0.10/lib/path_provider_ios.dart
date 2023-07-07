// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'messages.g.dart';

/// The iOS implementation of [PathProviderPlatform].
class PathProviderIOS extends PathProviderPlatform {
  /// The method channel used to interact with the native platform.
  final PathProviderApi _pathProvider = PathProviderApi();

  /// Registers this class as the default instance of [PathProviderPlatform]
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderIOS();
  }

  @override
  Future<String?> getTemporaryPath() async {
    return _pathProvider.getTemporaryPath();
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final String? path = await _pathProvider.getApplicationSupportPath();
    if (path != null) {
      // Ensure the directory exists before returning it, for consistency with
      // other platforms.
      await Directory(path).create(recursive: true);
    }
    return path;
  }

  @override
  Future<String?> getLibraryPath() async {
    return _pathProvider.getLibraryPath();
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _pathProvider.getApplicationDocumentsPath();
  }

  @override
  Future<String?> getExternalStoragePath() async {
    throw UnsupportedError('getExternalStoragePath is not supported on iOS');
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    throw UnsupportedError('getExternalCachePaths is not supported on iOS');
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    throw UnsupportedError('getExternalStoragePaths is not supported on iOS');
  }

  @override
  Future<String?> getDownloadsPath() async {
    throw UnsupportedError('getDownloadsPath is not supported on iOS');
  }
}
