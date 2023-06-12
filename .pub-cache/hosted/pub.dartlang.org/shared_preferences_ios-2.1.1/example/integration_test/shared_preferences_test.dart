// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesIos', () {
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
    String _prefixedKey(String key) {
      return 'flutter.$key';
    }

    testWidgets('reading', (WidgetTester _) async {
      final Map<String, Object> values = await preferences.getAll();
      expect(values[_prefixedKey('String')], isNull);
      expect(values[_prefixedKey('bool')], isNull);
      expect(values[_prefixedKey('int')], isNull);
      expect(values[_prefixedKey('double')], isNull);
      expect(values[_prefixedKey('List')], isNull);
    });

    testWidgets('writing', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setValue(
            'String', _prefixedKey('String'), kTestValues2['flutter.String']!),
        preferences.setValue(
            'Bool', _prefixedKey('bool'), kTestValues2['flutter.bool']!),
        preferences.setValue(
            'Int', _prefixedKey('int'), kTestValues2['flutter.int']!),
        preferences.setValue(
            'Double', _prefixedKey('double'), kTestValues2['flutter.double']!),
        preferences.setValue(
            'StringList', _prefixedKey('List'), kTestValues2['flutter.List']!)
      ]);
      final Map<String, Object> values = await preferences.getAll();
      expect(values[_prefixedKey('String')], kTestValues2['flutter.String']);
      expect(values[_prefixedKey('bool')], kTestValues2['flutter.bool']);
      expect(values[_prefixedKey('int')], kTestValues2['flutter.int']);
      expect(values[_prefixedKey('double')], kTestValues2['flutter.double']);
      expect(values[_prefixedKey('List')], kTestValues2['flutter.List']);
    });

    testWidgets('removing', (WidgetTester _) async {
      final String key = _prefixedKey('testKey');
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
  });
}
