// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:path/path.dart' as path;
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// The Linux implementation of [SharedPreferencesStorePlatform].
///
/// This class implements the `package:shared_preferences` functionality for Linux.
class SharedPreferencesLinux extends SharedPreferencesStorePlatform {
  /// Deprecated instance of [SharedPreferencesLinux].
  /// Use [SharedPreferencesStorePlatform.instance] instead.
  @Deprecated('Use `SharedPreferencesStorePlatform.instance` instead.')
  static SharedPreferencesLinux instance = SharedPreferencesLinux();

  /// Registers the Linux implementation.
  static void registerWith() {
    SharedPreferencesStorePlatform.instance = SharedPreferencesLinux();
  }

  /// Local copy of preferences
  Map<String, Object>? _cachedPreferences;

  /// File system used to store to disk. Exposed for testing only.
  @visibleForTesting
  FileSystem fs = const LocalFileSystem();

  /// The path_provider_linux instance used to find the support directory.
  @visibleForTesting
  PathProviderLinux pathProvider = PathProviderLinux();

  /// Gets the file where the preferences are stored.
  Future<File?> _getLocalDataFile() async {
    final String? directory = await pathProvider.getApplicationSupportPath();
    if (directory == null) {
      return null;
    }
    return fs.file(path.join(directory, 'shared_preferences.json'));
  }

  /// Gets the preferences from the stored file. Once read, the preferences are
  /// maintained in memory.
  Future<Map<String, Object>> _readPreferences() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    Map<String, Object> preferences = <String, Object>{};
    final File? localDataFile = await _getLocalDataFile();
    if (localDataFile != null && localDataFile.existsSync()) {
      final String stringMap = localDataFile.readAsStringSync();
      if (stringMap.isNotEmpty) {
        final Object? data = json.decode(stringMap);
        if (data is Map) {
          preferences = data.cast<String, Object>();
        }
      }
    }
    _cachedPreferences = preferences;
    return preferences;
  }

  /// Writes the cached preferences to disk. Returns [true] if the operation
  /// succeeded.
  Future<bool> _writePreferences(Map<String, Object> preferences) async {
    try {
      final File? localDataFile = await _getLocalDataFile();
      if (localDataFile == null) {
        debugPrint('Unable to determine where to write preferences.');
        return false;
      }
      if (!localDataFile.existsSync()) {
        localDataFile.createSync(recursive: true);
      }
      final String stringMap = json.encode(preferences);
      localDataFile.writeAsStringSync(stringMap);
    } catch (e) {
      debugPrint('Error saving preferences to disk: $e');
      return false;
    }
    return true;
  }

  @override
  Future<bool> clear() async {
    final Map<String, Object> preferences = await _readPreferences();
    preferences.clear();
    return _writePreferences(preferences);
  }

  @override
  Future<Map<String, Object>> getAll() async {
    return _readPreferences();
  }

  @override
  Future<bool> remove(String key) async {
    final Map<String, Object> preferences = await _readPreferences();
    preferences.remove(key);
    return _writePreferences(preferences);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final Map<String, Object> preferences = await _readPreferences();
    preferences[key] = value;
    return _writePreferences(preferences);
  }
}
