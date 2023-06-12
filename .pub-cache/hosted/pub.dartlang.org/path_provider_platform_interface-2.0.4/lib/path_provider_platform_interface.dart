// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/enums.dart';
import 'src/method_channel_path_provider.dart';

export 'src/enums.dart';

/// The interface that implementations of path_provider must implement.
///
/// Platform implementations should extend this class rather than implement it as `PathProvider`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [PathProviderPlatform] methods.
abstract class PathProviderPlatform extends PlatformInterface {
  /// Constructs a PathProviderPlatform.
  PathProviderPlatform() : super(token: _token);

  static final Object _token = Object();

  static PathProviderPlatform _instance = MethodChannelPathProvider();

  /// The default instance of [PathProviderPlatform] to use.
  ///
  /// Defaults to [MethodChannelPathProvider].
  static PathProviderPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [PathProviderPlatform] when they register themselves.
  static set instance(PathProviderPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Path to the temporary directory on the device that is not backed up and is
  /// suitable for storing caches of downloaded files.
  Future<String?> getTemporaryPath() {
    throw UnimplementedError('getTemporaryPath() has not been implemented.');
  }

  /// Path to a directory where the application may place application support
  /// files.
  Future<String?> getApplicationSupportPath() {
    throw UnimplementedError(
        'getApplicationSupportPath() has not been implemented.');
  }

  /// Path to the directory where application can store files that are persistent,
  /// backed up, and not visible to the user, such as sqlite.db.
  Future<String?> getLibraryPath() {
    throw UnimplementedError('getLibraryPath() has not been implemented.');
  }

  /// Path to a directory where the application may place data that is
  /// user-generated, or that cannot otherwise be recreated by your application.
  Future<String?> getApplicationDocumentsPath() {
    throw UnimplementedError(
        'getApplicationDocumentsPath() has not been implemented.');
  }

  /// Path to a directory where the application may access top level storage.
  /// The current operating system should be determined before issuing this
  /// function call, as this functionality is only available on Android.
  Future<String?> getExternalStoragePath() {
    throw UnimplementedError(
        'getExternalStoragePath() has not been implemented.');
  }

  /// Paths to directories where application specific external cache data can be
  /// stored. These paths typically reside on external storage like separate
  /// partitions or SD cards. Phones may have multiple storage directories
  /// available.
  Future<List<String>?> getExternalCachePaths() {
    throw UnimplementedError(
        'getExternalCachePaths() has not been implemented.');
  }

  /// Paths to directories where application specific data can be stored.
  /// These paths typically reside on external storage like separate partitions
  /// or SD cards. Phones may have multiple storage directories available.
  Future<List<String>?> getExternalStoragePaths({
    /// Optional parameter. See [StorageDirectory] for more informations on
    /// how this type translates to Android storage directories.
    StorageDirectory? type,
  }) {
    throw UnimplementedError(
        'getExternalStoragePaths() has not been implemented.');
  }

  /// Path to the directory where downloaded files can be stored.
  /// This is typically only relevant on desktop operating systems.
  Future<String?> getDownloadsPath() {
    throw UnimplementedError('getDownloadsPath() has not been implemented.');
  }
}
