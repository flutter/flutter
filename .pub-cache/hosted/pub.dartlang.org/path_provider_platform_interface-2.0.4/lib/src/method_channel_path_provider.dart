// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:platform/platform.dart';

/// An implementation of [PathProviderPlatform] that uses method channels.
class MethodChannelPathProvider extends PathProviderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  MethodChannel methodChannel =
      const MethodChannel('plugins.flutter.io/path_provider');

  // Ideally, this property shouldn't exist, and each platform should
  // just implement the supported methods. Once all the platforms are
  // federated, this property should be removed.
  Platform _platform = const LocalPlatform();

  /// This API is only exposed for the unit tests. It should not be used by
  /// any code outside of the plugin itself.
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void setMockPathProviderPlatform(Platform platform) {
    _platform = platform;
  }

  @override
  Future<String?> getTemporaryPath() {
    return methodChannel.invokeMethod<String>('getTemporaryDirectory');
  }

  @override
  Future<String?> getApplicationSupportPath() {
    return methodChannel.invokeMethod<String>('getApplicationSupportDirectory');
  }

  @override
  Future<String?> getLibraryPath() {
    if (!_platform.isIOS && !_platform.isMacOS) {
      throw UnsupportedError('Functionality only available on iOS/macOS');
    }
    return methodChannel.invokeMethod<String>('getLibraryDirectory');
  }

  @override
  Future<String?> getApplicationDocumentsPath() {
    return methodChannel
        .invokeMethod<String>('getApplicationDocumentsDirectory');
  }

  @override
  Future<String?> getExternalStoragePath() {
    if (!_platform.isAndroid) {
      throw UnsupportedError('Functionality only available on Android');
    }
    return methodChannel.invokeMethod<String>('getStorageDirectory');
  }

  @override
  Future<List<String>?> getExternalCachePaths() {
    if (!_platform.isAndroid) {
      throw UnsupportedError('Functionality only available on Android');
    }
    return methodChannel
        .invokeListMethod<String>('getExternalCacheDirectories');
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    if (!_platform.isAndroid) {
      throw UnsupportedError('Functionality only available on Android');
    }
    return methodChannel.invokeListMethod<String>(
      'getExternalStorageDirectories',
      <String, dynamic>{'type': type?.index},
    );
  }

  @override
  Future<String?> getDownloadsPath() {
    if (!_platform.isMacOS) {
      throw UnsupportedError('Functionality only available on macOS');
    }
    return methodChannel.invokeMethod<String>('getDownloadsDirectory');
  }
}
