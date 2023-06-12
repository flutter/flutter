// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';

const Map<String, dynamic> kTestValues = <String, dynamic>{
  'flutter.String': 'hello world',
  'flutter.Bool': true,
  'flutter.Int': 42,
  'flutter.Double': 3.14159,
  'flutter.StringList': <String>['foo', 'bar'],
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesPlugin', () {
    setUp(() {
      html.window.localStorage.clear();
    });

    testWidgets('registers itself', (WidgetTester tester) async {
      SharedPreferencesStorePlatform.instance =
          MethodChannelSharedPreferencesStore();
      expect(SharedPreferencesStorePlatform.instance,
          isNot(isA<SharedPreferencesPlugin>()));
      SharedPreferencesPlugin.registerWith(null);
      expect(SharedPreferencesStorePlatform.instance,
          isA<SharedPreferencesPlugin>());
    });

    testWidgets('getAll', (WidgetTester tester) async {
      final SharedPreferencesPlugin store = SharedPreferencesPlugin();
      expect(await store.getAll(), isEmpty);

      html.window.localStorage['flutter.testKey'] = '"test value"';
      html.window.localStorage['unprefixed_key'] = 'not a flutter value';
      final Map<String, Object> allData = await store.getAll();
      expect(allData, hasLength(1));
      expect(allData['flutter.testKey'], 'test value');
    });

    testWidgets('remove', (WidgetTester tester) async {
      final SharedPreferencesPlugin store = SharedPreferencesPlugin();
      html.window.localStorage['flutter.testKey'] = '"test value"';
      expect(html.window.localStorage['flutter.testKey'], isNotNull);
      expect(await store.remove('flutter.testKey'), isTrue);
      expect(html.window.localStorage['flutter.testKey'], isNull);
      expect(
        () => store.remove('unprefixed'),
        throwsA(isA<FormatException>()),
      );
    });

    testWidgets('setValue', (WidgetTester tester) async {
      final SharedPreferencesPlugin store = SharedPreferencesPlugin();
      for (final String key in kTestValues.keys) {
        final dynamic value = kTestValues[key];
        expect(await store.setValue(key.split('.').last, key, value), true);
      }
      expect(html.window.localStorage.keys, hasLength(kTestValues.length));
      for (final String key in html.window.localStorage.keys) {
        expect(html.window.localStorage[key], json.encode(kTestValues[key]));
      }

      // Check that generics are preserved.
      expect((await store.getAll())['flutter.StringList'], isA<List<String>>());

      // Invalid key format.
      expect(
        () => store.setValue('String', 'unprefixed', 'hello'),
        throwsA(isA<FormatException>()),
      );
    });

    testWidgets('clear', (WidgetTester tester) async {
      final SharedPreferencesPlugin store = SharedPreferencesPlugin();
      html.window.localStorage['flutter.testKey1'] = '"test value"';
      html.window.localStorage['flutter.testKey2'] = '42';
      html.window.localStorage['unprefixed_key'] = 'not a flutter value';
      expect(await store.clear(), isTrue);
      expect(html.window.localStorage.keys.single, 'unprefixed_key');
    });
  });
}
