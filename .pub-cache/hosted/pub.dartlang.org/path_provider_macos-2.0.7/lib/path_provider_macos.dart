// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'messages.g.dart';

/// The macOS implementation of [PathProviderPlatform].
class PathProviderMacOS extends PathProviderPlatform {
  final PathProviderApi _pathProvider = PathProviderApi();

  /// Registers this class as the default instance of [PathProviderPlatform]
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderMacOS();
  }

  @override
  Future<String?> getTemporaryPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.temp);
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final String? path =
        await _pathProvider.getDirectoryPath(DirectoryType.applicationSupport);
    if (path != null) {
      // Ensure the directory exists before returning it, for consistency with
      // other platforms.
      await Directory(path).create(recursive: true);
    }
    return path;
  }

  @override
  Future<String?> getLibraryPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.library);
  }

  @override
  Future<String?> getApplicationDocumentsPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.applicationDocuments);
  }

  @override
  Future<String?> getExternalStoragePath() async {
    throw UnsupportedError('getExternalStoragePath is not supported on macOS');
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    throw UnsupportedError('getExternalCachePaths is not supported on macOS');
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    throw UnsupportedError('getExternalStoragePaths is not supported on macOS');
  }

  @override
  Future<String?> getDownloadsPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.downloads);
  }
}
