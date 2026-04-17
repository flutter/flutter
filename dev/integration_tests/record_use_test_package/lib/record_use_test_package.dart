// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';

Map<String, String>? _cachedTranslations;

Future<Map<String, String>> _getTranslations() async {
  if (_cachedTranslations != null) {
    return _cachedTranslations!;
  }
  final String jsonString =
      await rootBundle.loadString('packages/record_use_test_package/data/translations.json');
  final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
  _cachedTranslations = jsonMap.cast<String, String>();
  return _cachedTranslations!;
}

// ignore: experimental_member_use
@RecordUse()
Future<String> translate(String key) async {
  final Map<String, String> translations = await _getTranslations();
  return translations[key] ?? 'Key not found: $key';
}

@visibleForTesting
Future<int> loadedTranslationsCount() async {
  final Map<String, String> translations = await _getTranslations();
  return translations.length;
}
