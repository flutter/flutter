// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesAndroid', () {
    const Map<String, Object> kTestValues = <String, Object>{
      'flutter.String': 'hello world',
      'flutter.bool': true,
      'flutter.int': 42,
      'flutter.double': 3.14159,
      'flutter.List': <String>['foo', 'bar'],
    };

    const Map<String, Object> kTestValues2 = <String, Object>{
      'flutter.String': 'goodbye world',
      'flutter.bool': false,
      'flutter.int': 1337,
      'flutter.double': 2.71828,
      'flutter.List': <String>['baz', 'quox'],
    };

    late SharedPreferencesStorePlatform preferences;

    setUp(() async {
      preferences = SharedPreferencesStorePlatform.instance;
    });

    tearDown(() {
      preferences.clear();
    });

    // Normally the app-facing package adds the prefix, but since this test
    // bypasses the app-facing package it needs to be manually added.
    String prefixedKey(String key) {
      return 'flutter.$key';
    }

    testWidgets('reading', (WidgetTester _) async {
      final Map<String, Object> values = await preferences.getAll();
      expect(values[prefixedKey('String')], isNull);
      expect(values[prefixedKey('bool')], isNull);
      expect(values[prefixedKey('int')], isNull);
      expect(values[prefixedKey('double')], isNull);
      expect(values[prefixedKey('List')], isNull);
    });

    testWidgets('writing', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setValue(
            'String', prefixedKey('String'), kTestValues2['flutter.String']!),
        preferences.setValue(
            'Bool', prefixedKey('bool'), kTestValues2['flutter.bool']!),
        preferences.setValue(
            'Int', prefixedKey('int'), kTestValues2['flutter.int']!),
        preferences.setValue(
            'Double', prefixedKey('double'), kTestValues2['flutter.double']!),
        preferences.setValue(
            'StringList', prefixedKey('List'), kTestValues2['flutter.List']!)
      ]);
      final Map<String, Object> values = await preferences.getAll();
      expect(values[prefixedKey('String')], kTestValues2['flutter.String']);
      expect(values[prefixedKey('bool')], kTestValues2['flutter.bool']);
      expect(values[prefixedKey('int')], kTestValues2['flutter.int']);
      expect(values[prefixedKey('double')], kTestValues2['flutter.double']);
      expect(values[prefixedKey('List')], kTestValues2['flutter.List']);
    });

    testWidgets('removing', (WidgetTester _) async {
      final String key = prefixedKey('testKey');
      await preferences.setValue('String', key, kTestValues['flutter.String']!);
      await preferences.setValue('Bool', key, kTestValues['flutter.bool']!);
      await preferences.setValue('Int', key, kTestValues['flutter.int']!);
      await preferences.setValue('Double', key, kTestValues['flutter.double']!);
      await preferences.setValue(
          'StringList', key, kTestValues['flutter.List']!);
      await preferences.remove(key);
      final Map<String, Object> values = await preferences.getAll();
      expect(values[key], isNull);
    });

    testWidgets('clearing', (WidgetTester _) async {
      await preferences.setValue(
          'String', 'String', kTestValues['flutter.String']!);
      await preferences.setValue('Bool', 'bool', kTestValues['flutter.bool']!);
      await preferences.setValue('Int', 'int', kTestValues['flutter.int']!);
      await preferences.setValue(
          'Double', 'double', kTestValues['flutter.double']!);
      await preferences.setValue(
          'StringList', 'List', kTestValues['flutter.List']!);
      await preferences.clear();
      final Map<String, Object> values = await preferences.getAll();
      expect(values['String'], null);
      expect(values['bool'], null);
      expect(values['int'], null);
      expect(values['double'], null);
      expect(values['List'], null);
    });

    testWidgets('simultaneous writes', (WidgetTester _) async {
      final List<Future<bool>> writes = <Future<bool>>[];
      const int writeCount = 100;
      for (int i = 1; i <= writeCount; i++) {
        writes.add(preferences.setValue('Int', prefixedKey('int'), i));
      }
      final List<bool> result = await Future.wait(writes, eagerError: true);
      // All writes should succeed.
      expect(result.where((bool element) => !element), isEmpty);
      // The last write should win.
      final Map<String, Object> values = await preferences.getAll();
      expect(values[prefixedKey('int')], writeCount);
    });

    testWidgets('string clash with lists, big integers and doubles',
        (WidgetTester _) async {
      final String key = prefixedKey('akey');
      const String value = 'a string value';
      await preferences.clear();

      // Special prefixes used to store datatypes that can't be stored directly
      // in SharedPreferences as strings instead.
      const List<String> specialPrefixes = <String>[
        // Prefix for lists:
        'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu',
        // Prefix for big integers:
        'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy',
        // Prefix for doubles:
        'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu',
      ];
      for (final String prefix in specialPrefixes) {
        expect(preferences.setValue('String', key, prefix + value),
            throwsA(isA<PlatformException>()));
        final Map<String, Object> values = await preferences.getAll();
        expect(values[key], null);
      }
    });
  });
}
