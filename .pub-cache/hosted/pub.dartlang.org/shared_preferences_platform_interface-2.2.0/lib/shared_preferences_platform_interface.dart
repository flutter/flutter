// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_shared_preferences.dart';

/// The interface that implementations of shared_preferences must implement.
///
/// Platform implementations should extend this class rather than implement it as `shared_preferences`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [SharedPreferencesStorePlatform] methods.
abstract class SharedPreferencesStorePlatform extends PlatformInterface {
  /// Constructs a SharedPreferencesStorePlatform.
  SharedPreferencesStorePlatform() : super(token: _token);

  static final Object _token = Object();

  /// The default instance of [SharedPreferencesStorePlatform] to use.
  ///
  /// Defaults to [MethodChannelSharedPreferencesStore].
  static SharedPreferencesStorePlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [SharedPreferencesStorePlatform] when they register themselves.
  static set instance(SharedPreferencesStorePlatform instance) {
    if (!instance.isMock) {
      PlatformInterface.verify(instance, _token);
    }
    _instance = instance;
  }

  static SharedPreferencesStorePlatform _instance =
      MethodChannelSharedPreferencesStore();

  /// Only mock implementations should set this to true.
  ///
  /// Mockito mocks are implementing this class with `implements` which is forbidden for anything
  /// other than mocks (see class docs). This property provides a backdoor for mockito mocks to
  /// skip the verification that the class isn't implemented with `implements`.
  @visibleForTesting
  @Deprecated('Use MockPlatformInterfaceMixin instead')
  bool get isMock => false;

  /// Removes the value associated with the [key].
  Future<bool> remove(String key);

  /// Stores the [value] associated with the [key].
  ///
  /// The [valueType] must match the type of [value] as follows:
  ///
  /// * Value type "Bool" must be passed if the value is of type `bool`.
  /// * Value type "Double" must be passed if the value is of type `double`.
  /// * Value type "Int" must be passed if the value is of type `int`.
  /// * Value type "String" must be passed if the value is of type `String`.
  /// * Value type "StringList" must be passed if the value is of type `List<String>`.
  Future<bool> setValue(String valueType, String key, Object value);

  /// Removes all keys and values in the store where the key starts with 'flutter.'.
  ///
  /// This default behavior is for backwards compatibility with older versions of this
  /// plugin, which did not support custom prefixes, and instead always used the
  /// prefix 'flutter.'.
  Future<bool> clear();

  /// Removes all keys and values in the store with given prefix.
  Future<bool> clearWithPrefix(String prefix) {
    throw UnimplementedError('clearWithPrefix is not implemented.');
  }

  /// Returns all key/value pairs persisted in this store where the key starts with 'flutter.'.
  ///
  /// This default behavior is for backwards compatibility with older versions of this
  /// plugin, which did not support custom prefixes, and instead always used the
  /// prefix 'flutter.'.
  Future<Map<String, Object>> getAll();

  /// Returns all key/value pairs persisting in this store that have given [prefix].
  Future<Map<String, Object>> getAllWithPrefix(String prefix) {
    throw UnimplementedError('getAllWithPrefix is not implemented.');
  }
}

/// Stores data in memory.
///
/// Data does not persist across application restarts. This is useful in unit-tests.
class InMemorySharedPreferencesStore extends SharedPreferencesStorePlatform {
  /// Instantiates an empty in-memory preferences store.
  InMemorySharedPreferencesStore.empty() : _data = <String, Object>{};

  /// Instantiates an in-memory preferences store containing a copy of [data].
  InMemorySharedPreferencesStore.withData(Map<String, Object> data)
      : _data = Map<String, Object>.from(data);

  final Map<String, Object> _data;
  static const String _defaultPrefix = 'flutter.';

  @override
  Future<bool> clear() async {
    return clearWithPrefix(_defaultPrefix);
  }

  @override
  Future<bool> clearWithPrefix(String prefix) async {
    _data.removeWhere((String key, _) => key.startsWith(prefix));
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    return getAllWithPrefix(_defaultPrefix);
  }

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) async {
    final Map<String, Object> preferences = Map<String, Object>.from(_data);
    preferences.removeWhere((String key, _) => !key.startsWith(prefix));
    return preferences;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    _data[key] = value;
    return true;
  }
}
