// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Wraps NSUserDefaults (on iOS) and SharedPreferences (on Android), providing
/// a persistent store for simple data.
///
/// Data is persisted to disk asynchronously.
class SharedPreferences {
  SharedPreferences._(this._preferenceCache);

  static String _prefix = 'flutter.';

  static bool _prefixHasBeenChanged = false;

  static Completer<SharedPreferences>? _completer;

  static SharedPreferencesStorePlatform get _store =>
      SharedPreferencesStorePlatform.instance;

  /// Sets the prefix that is attached to all keys for all shared preferences.
  ///
  /// This changes the inputs when adding data to preferences as well as
  /// setting the filter that determines what data will be returned
  /// from the `getInstance` method.
  ///
  /// By default, the prefix is 'flutter.', which is compatible with the
  /// previous behavior of this plugin. To use preferences with no prefix,
  /// set [prefix] to ''.
  ///
  /// No migration of existing preferences is performed by this method.
  /// If you set a different prefix, and have previously stored preferences,
  /// you will need to handle any migration yourself.
  ///
  /// This cannot be called after `getInstance`.
  static void setPrefix(String prefix) {
    if (_completer != null) {
      throw StateError('setPrefix cannot be called after getInstance');
    }
    _prefix = prefix;
    _prefixHasBeenChanged = true;
  }

  /// Resets class's static values to allow for testing of setPrefix flow.
  @visibleForTesting
  static void resetStatic() {
    _completer = null;
    _prefix = 'flutter.';
    _prefixHasBeenChanged = false;
  }

  /// Loads and parses the [SharedPreferences] for this app from disk.
  ///
  /// Because this is reading from disk, it shouldn't be awaited in
  /// performance-sensitive blocks.
  static Future<SharedPreferences> getInstance() async {
    if (_completer == null) {
      final Completer<SharedPreferences> completer =
          Completer<SharedPreferences>();
      _completer = completer;
      try {
        final Map<String, Object> preferencesMap =
            await _getSharedPreferencesMap();
        completer.complete(SharedPreferences._(preferencesMap));
      } catch (e) {
        // If there's an error, explicitly return the future with an error.
        // then set the completer to null so we can retry.
        completer.completeError(e);
        final Future<SharedPreferences> sharedPrefsFuture = completer.future;
        _completer = null;
        return sharedPrefsFuture;
      }
    }
    return _completer!.future;
  }

  /// The cache that holds all preferences.
  ///
  /// It is instantiated to the current state of the SharedPreferences or
  /// NSUserDefaults object and then kept in sync via setter methods in this
  /// class.
  ///
  /// It is NOT guaranteed that this cache and the device prefs will remain
  /// in sync since the setter method might fail for any reason.
  final Map<String, Object> _preferenceCache;

  /// Returns all keys in the persistent storage.
  Set<String> getKeys() => Set<String>.from(_preferenceCache.keys);

  /// Reads a value of any type from persistent storage.
  Object? get(String key) => _preferenceCache[key];

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// bool.
  bool? getBool(String key) => _preferenceCache[key] as bool?;

  /// Reads a value from persistent storage, throwing an exception if it's not
  /// an int.
  int? getInt(String key) => _preferenceCache[key] as int?;

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// double.
  double? getDouble(String key) => _preferenceCache[key] as double?;

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// String.
  String? getString(String key) => _preferenceCache[key] as String?;

  /// Returns true if persistent storage the contains the given [key].
  bool containsKey(String key) => _preferenceCache.containsKey(key);

  /// Reads a set of string values from persistent storage, throwing an
  /// exception if it's not a string set.
  List<String>? getStringList(String key) {
    List<dynamic>? list = _preferenceCache[key] as List<dynamic>?;
    if (list != null && list is! List<String>) {
      list = list.cast<String>().toList();
      _preferenceCache[key] = list;
    }
    // Make a copy of the list so that later mutations won't propagate
    return list?.toList() as List<String>?;
  }

  /// Saves a boolean [value] to persistent storage in the background.
  Future<bool> setBool(String key, bool value) => _setValue('Bool', key, value);

  /// Saves an integer [value] to persistent storage in the background.
  Future<bool> setInt(String key, int value) => _setValue('Int', key, value);

  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  Future<bool> setDouble(String key, double value) =>
      _setValue('Double', key, value);

  /// Saves a string [value] to persistent storage in the background.
  ///
  /// Note: Due to limitations in Android's SharedPreferences,
  /// values cannot start with any one of the following:
  ///
  /// - 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu'
  /// - 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy'
  /// - 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu'
  Future<bool> setString(String key, String value) =>
      _setValue('String', key, value);

  /// Saves a list of strings [value] to persistent storage in the background.
  Future<bool> setStringList(String key, List<String> value) =>
      _setValue('StringList', key, value);

  /// Removes an entry from persistent storage.
  Future<bool> remove(String key) {
    final String prefixedKey = '$_prefix$key';
    _preferenceCache.remove(key);
    return _store.remove(prefixedKey);
  }

  Future<bool> _setValue(String valueType, String key, Object value) {
    ArgumentError.checkNotNull(value, 'value');
    final String prefixedKey = '$_prefix$key';
    if (value is List<String>) {
      // Make a copy of the list so that later mutations won't propagate
      _preferenceCache[key] = value.toList();
    } else {
      _preferenceCache[key] = value;
    }
    return _store.setValue(valueType, prefixedKey, value);
  }

  /// Always returns true.
  /// On iOS, synchronize is marked deprecated. On Android, we commit every set.
  @Deprecated('This method is now a no-op, and should no longer be called.')
  Future<bool> commit() async => true;

  /// Completes with true once the user preferences for the app has been cleared.
  Future<bool> clear() {
    _preferenceCache.clear();
    if (_prefixHasBeenChanged) {
      try {
        return _store.clearWithPrefix(_prefix);
      } catch (e) {
        // Catching and clarifying UnimplementedError to provide a more robust message.
        if (e is UnimplementedError) {
          throw UnimplementedError('''
This implementation of Shared Preferences doesn't yet support the setPrefix method.
Either update the implementation to support setPrefix, or do not call setPrefix.
        ''');
        } else {
          rethrow;
        }
      }
    }
    return _store.clear();
  }

  /// Fetches the latest values from the host platform.
  ///
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  Future<void> reload() async {
    final Map<String, Object> preferences =
        await SharedPreferences._getSharedPreferencesMap();
    _preferenceCache.clear();
    _preferenceCache.addAll(preferences);
  }

  static Future<Map<String, Object>> _getSharedPreferencesMap() async {
    final Map<String, Object> fromSystem = <String, Object>{};
    if (_prefixHasBeenChanged) {
      try {
        fromSystem.addAll(await _store.getAllWithPrefix(_prefix));
      } catch (e) {
        // Catching and clarifying UnimplementedError to provide a more robust message.
        if (e is UnimplementedError) {
          throw UnimplementedError('''
This implementation of Shared Preferences doesn't yet support the setPrefix method.
Either update the implementation to support setPrefix, or do not call setPrefix.
        ''');
        } else {
          rethrow;
        }
      }
    } else {
      fromSystem.addAll(await _store.getAll());
    }

    if (_prefix.isEmpty) {
      return fromSystem;
    }
    // Strip the prefix from the returned preferences.
    final Map<String, Object> preferencesMap = <String, Object>{};
    for (final String key in fromSystem.keys) {
      assert(key.startsWith(_prefix));
      preferencesMap[key.substring(_prefix.length)] = fromSystem[key]!;
    }
    return preferencesMap;
  }

  /// Initializes the shared preferences with mock values for testing.
  ///
  /// If the singleton instance has been initialized already, it is nullified.
  @visibleForTesting
  static void setMockInitialValues(Map<String, Object> values) {
    final Map<String, Object> newValues =
        values.map<String, Object>((String key, Object value) {
      String newKey = key;
      if (!key.startsWith(_prefix)) {
        newKey = '$_prefix$key';
      }
      return MapEntry<String, Object>(newKey, value);
    });
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.withData(newValues);
    _completer = null;
  }
}
