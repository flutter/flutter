// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'messages.g.dart' as messages;

messages.StorageDirectory _convertStorageDirectory(
    StorageDirectory? directory) {
  switch (directory) {
    case null:
      return messages.StorageDirectory.root;
    case StorageDirectory.music:
      return messages.StorageDirectory.music;
    case StorageDirectory.podcasts:
      return messages.StorageDirectory.podcasts;
    case StorageDirectory.ringtones:
      return messages.StorageDirectory.ringtones;
    case StorageDirectory.alarms:
      return messages.StorageDirectory.alarms;
    case StorageDirectory.notifications:
      return messages.StorageDirectory.notifications;
    case StorageDirectory.pictures:
      return messages.StorageDirectory.pictures;
    case StorageDirectory.movies:
      return messages.StorageDirectory.movies;
    case StorageDirectory.downloads:
      return messages.StorageDirectory.downloads;
    case StorageDirectory.dcim:
      return messages.StorageDirectory.dcim;
    case StorageDirectory.documents:
      return messages.StorageDirectory.documents;
  }
}

/// The Android implementation of [PathProviderPlatform].
class PathProviderAndroid extends PathProviderPlatform {
  final messages.PathProviderApi _api = messages.PathProviderApi();

  /// Registers this class as the default instance of [PathProviderPlatform].
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderAndroid();
  }

  @override
  Future<String?> getTemporaryPath() {
    return _api.getTemporaryPath();
  }

  @override
  Future<String?> getApplicationSupportPath() {
    return _api.getApplicationSupportPath();
  }

  @override
  Future<String?> getLibraryPath() {
    throw UnsupportedError('getLibraryPath is not supported on Android');
  }

  @override
  Future<String?> getApplicationDocumentsPath() {
    return _api.getApplicationDocumentsPath();
  }

  @override
  Future<String?> getExternalStoragePath() {
    return _api.getExternalStoragePath();
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return (await _api.getExternalCachePaths()).cast<String>();
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return (await _api.getExternalStoragePaths(_convertStorageDirectory(type)))
        .cast<String>();
  }

  @override
  Future<String?> getDownloadsPath() {
    throw UnsupportedError('getDownloadsPath is not supported on Android');
  }
}
