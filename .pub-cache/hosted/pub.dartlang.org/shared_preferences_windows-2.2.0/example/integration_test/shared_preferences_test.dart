// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesWindows', () {
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

    testWidgets('reading', (WidgetTester _) async {
      final SharedPreferencesWindows preferences = SharedPreferencesWindows();
      preferences.clear();
      final Map<String, Object> values = await preferences.getAll();
      expect(values['String'], isNull);
      expect(values['bool'], isNull);
      expect(values['int'], isNull);
      expect(values['double'], isNull);
      expect(values['List'], isNull);
    });

    testWidgets('writing', (WidgetTester _) async {
      final SharedPreferencesWindows preferences = SharedPreferencesWindows();
      preferences.clear();
      await preferences.setValue(
          'String', 'flutter.String', kTestValues2['flutter.String']!);
      await preferences.setValue(
          'Bool', 'flutter.bool', kTestValues2['flutter.bool']!);
      await preferences.setValue(
          'Int', 'flutter.int', kTestValues2['flutter.int']!);
      await preferences.setValue(
          'Double', 'flutter.double', kTestValues2['flutter.double']!);
      await preferences.setValue(
          'StringList', 'flutter.List', kTestValues2['flutter.List']!);
      final Map<String, Object> values = await preferences.getAll();
      expect(values['flutter.String'], kTestValues2['flutter.String']);
      expect(values['flutter.bool'], kTestValues2['flutter.bool']);
      expect(values['flutter.int'], kTestValues2['flutter.int']);
      expect(values['flutter.double'], kTestValues2['flutter.double']);
      expect(values['flutter.List'], kTestValues2['flutter.List']);
    });

    testWidgets('removing', (WidgetTester _) async {
      final SharedPreferencesWindows preferences = SharedPreferencesWindows();
      preferences.clear();
      const String key = 'flutter.testKey';
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
      final SharedPreferencesWindows preferences = SharedPreferencesWindows();
      preferences.clear();
      await preferences.setValue(
          'String', 'flutter.String', kTestValues['flutter.String']!);
      await preferences.setValue(
          'Bool', 'flutter.bool', kTestValues['flutter.bool']!);
      await preferences.setValue(
          'Int', 'flutter.int', kTestValues['flutter.int']!);
      await preferences.setValue(
          'Double', 'flutter.double', kTestValues['flutter.double']!);
      await preferences.setValue(
          'StringList', 'flutter.List', kTestValues['flutter.List']!);
      await preferences.clear();
      final Map<String, Object> values = await preferences.getAll();
      expect(values['flutter.String'], null);
      expect(values['flutter.bool'], null);
      expect(values['flutter.int'], null);
      expect(values['flutter.double'], null);
      expect(values['flutter.List'], null);
    });
  });
}
