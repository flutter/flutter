// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../cache.dart';
import 'custom_device_config.dart';

/// Represents the custom devices config file on disk which in turn
/// contains a list of individual custom device configs.
class CustomDevicesConfig {
  /// Load a [CustomDevicesConfig] from a (possibly non-existent) location on disk.
  ///
  /// The config is loaded on construction. Any error while loading will be logged
  /// but will not result in an exception being thrown. The file will not be deleted
  /// when it's not valid JSON (which other configurations do) and will not
  /// be implicitly created when it doesn't exist.
  CustomDevicesConfig({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform
  }) : _fileSystem = fileSystem,
       _config = Config(
         _kCustomDevicesConfigName,
         fileSystem: fileSystem,
         logger: logger,
         platform: platform,
         deleteFileOnFormatException: false
       )
  {
    ensureFileExists();
  }

  @visibleForTesting
  CustomDevicesConfig.test({
    @required FileSystem fileSystem,
    Directory directory,
    @required Logger logger
  }) : _fileSystem = fileSystem,
       _config = Config.test(
         name: _kCustomDevicesConfigName,
         directory: directory,
         logger: logger,
         deleteFileOnFormatException: false
       )
  {
    ensureFileExists();
  }

  static const String _kCustomDevicesConfigName = 'custom_devices.json';
  static const String _kCustomDevicesConfigKey = 'custom-devices';
  static const String _kSchema = r'$schema';
  static const String _kCustomDevices = 'custom-devices';

  final FileSystem _fileSystem;
  final Config _config;

  String get _defaultSchema {
    final Uri uri = _fileSystem
      .directory(Cache.flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory('static')
      .childFile('custom-devices.schema.json')
      .uri;

    // otherwise it won't contain the Uri schema, so the file:// at the start
    // will be missing
    assert(uri.isAbsolute);

    return uri.toString();
  }

  /// Ensure the config file exists on disk by creating one with default values
  /// if it doesn't exist yet.
  ///
  /// The config file should always be present so we can give the user a path
  /// to a file they can edit.
  void ensureFileExists() {
    if (!_fileSystem.file(_config.configPath).existsSync()) {
      _config.setValue(_kSchema, _defaultSchema);
      _config.setValue(_kCustomDevices, <dynamic>[CustomDeviceConfig.example.toJson()]);
    }
  }

  /// Get the list of [CustomDeviceConfig]s that are listed in the config file
  /// including disabled ones.
  ///
  /// Returns an empty list when the config could not be loaded.
  List<CustomDeviceConfig> get devices {
    final dynamic json = _config.getValue(_kCustomDevicesConfigKey);

    if (json == null) {
      return <CustomDeviceConfig>[];
    }

    final List<dynamic> typedList = json as List<dynamic>;

    return typedList.map((dynamic e) => CustomDeviceConfig.fromJson(e)).toList();
  }

  // We don't have a setter for devices here because we don't need it and
  // it also may overwrite any things done by the user that aren't explicitly
  // tracked by the JSON-representation. For example comments (not possible right now,
  // but they'd be useful so maybe in the future) or formatting.
}
