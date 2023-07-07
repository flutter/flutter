// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'src/messages.g.dart';

/// The Android implementation of [SharedPreferencesStorePlatform].
///
/// This class implements the `package:shared_preferences` functionality for Android.
class SharedPreferencesAndroid extends SharedPreferencesStorePlatform {
  /// Creates a new plugin implementation instance.
  SharedPreferencesAndroid({
    @visibleForTesting SharedPreferencesApi? api,
  }) : _api = api ?? SharedPreferencesApi();

  final SharedPreferencesApi _api;

  /// Registers this class as the default instance of [SharedPreferencesStorePlatform].
  static void registerWith() {
    SharedPreferencesStorePlatform.instance = SharedPreferencesAndroid();
  }

  static const String _defaultPrefix = 'flutter.';

  @override
  Future<bool> remove(String key) async {
    return _api.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    switch (valueType) {
      case 'String':
        return _api.setString(key, value as String);
      case 'Bool':
        return _api.setBool(key, value as bool);
      case 'Int':
        return _api.setInt(key, value as int);
      case 'Double':
        return _api.setDouble(key, value as double);
      case 'StringList':
        return _api.setStringList(key, value as List<String>);
    }
    // TODO(tarrinneal): change to ArgumentError across all platforms.
    throw PlatformException(
        code: 'InvalidOperation',
        message: '"$valueType" is not a supported type.');
  }

  @override
  Future<bool> clear() {
    return clearWithPrefix(_defaultPrefix);
  }

  @override
  Future<bool> clearWithPrefix(String prefix) async {
    return _api.clearWithPrefix(prefix);
  }

  @override
  Future<Map<String, Object>> getAll() {
    return getAllWithPrefix(_defaultPrefix);
  }

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) async {
    final Map<String?, Object?> data = await _api.getAllWithPrefix(prefix);
    return data.cast<String, Object>();
  }
}
