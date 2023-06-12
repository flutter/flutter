// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// The web implementation of [SharedPreferencesStorePlatform].
///
/// This class implements the `package:shared_preferences` functionality for the web.
class SharedPreferencesPlugin extends SharedPreferencesStorePlatform {
  /// Registers this class as the default instance of [SharedPreferencesStorePlatform].
  static void registerWith(Registrar? registrar) {
    SharedPreferencesStorePlatform.instance = SharedPreferencesPlugin();
  }

  @override
  Future<bool> clear() async {
    // IMPORTANT: Do not use html.window.localStorage.clear() as that will
    //            remove _all_ local data, not just the keys prefixed with
    //            "flutter."
    _storedFlutterKeys.forEach(html.window.localStorage.remove);
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    final Map<String, Object> allData = <String, Object>{};
    for (final String key in _storedFlutterKeys) {
      allData[key] = _decodeValue(html.window.localStorage[key]!);
    }
    return allData;
  }

  @override
  Future<bool> remove(String key) async {
    _checkPrefix(key);
    html.window.localStorage.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object? value) async {
    _checkPrefix(key);
    html.window.localStorage[key] = _encodeValue(value);
    return true;
  }

  void _checkPrefix(String key) {
    if (!key.startsWith('flutter.')) {
      throw FormatException(
        'Shared preferences keys must start with prefix "flutter.".',
        key,
        0,
      );
    }
  }

  Iterable<String> get _storedFlutterKeys {
    return html.window.localStorage.keys
        .where((String key) => key.startsWith('flutter.'));
  }

  String _encodeValue(Object? value) {
    return json.encode(value);
  }

  Object _decodeValue(String encodedValue) {
    final Object? decodedValue = json.decode(encodedValue);

    if (decodedValue is List) {
      // JSON does not preserve generics. The encode/decode roundtrip is
      // `List<String>` => JSON => `List<dynamic>`. We have to explicitly
      // restore the RTTI.
      return decodedValue.cast<String>();
    }

    return decodedValue!;
  }
}
