// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(MethodChannelSharedPreferencesStore, () {
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/shared_preferences_android',
    );

    const Map<String, Object> kTestValues = <String, Object>{
      'flutter.String': 'hello world',
      'flutter.Bool': true,
      'flutter.Int': 42,
      'flutter.Double': 3.14159,
      'flutter.StringList': <String>['foo', 'bar'],
    };
    // Create a dummy in-memory implementation to back the mocked method channel
    // API to simplify validation of the expected calls.
    late InMemorySharedPreferencesStore testData;

    final List<MethodCall> log = <MethodCall>[];
    late SharedPreferencesStorePlatform store;

    setUp(() async {
      testData = InMemorySharedPreferencesStore.empty();

      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'getAll') {
          return await testData.getAll();
        }
        if (methodCall.method == 'remove') {
          final String key = methodCall.arguments['key']! as String;
          return await testData.remove(key);
        }
        if (methodCall.method == 'clear') {
          return await testData.clear();
        }
        final RegExp setterRegExp = RegExp(r'set(.*)');
        final Match? match = setterRegExp.matchAsPrefix(methodCall.method);
        if (match?.groupCount == 1) {
          final String valueType = match!.group(1)!;
          final String key = methodCall.arguments['key'] as String;
          final Object value = methodCall.arguments['value'] as Object;
          return await testData.setValue(valueType, key, value);
        }
        fail('Unexpected method call: ${methodCall.method}');
      });
      log.clear();
    });

    test('registered instance', () {
      SharedPreferencesAndroid.registerWith();
      expect(SharedPreferencesStorePlatform.instance,
          isA<SharedPreferencesAndroid>());
    });

    test('getAll', () async {
      store = SharedPreferencesAndroid();
      testData = InMemorySharedPreferencesStore.withData(kTestValues);
      expect(await store.getAll(), kTestValues);
      expect(log.single.method, 'getAll');
    });

    test('remove', () async {
      store = SharedPreferencesAndroid();
      testData = InMemorySharedPreferencesStore.withData(kTestValues);
      expect(await store.remove('flutter.String'), true);
      expect(await store.remove('flutter.Bool'), true);
      expect(await store.remove('flutter.Int'), true);
      expect(await store.remove('flutter.Double'), true);
      expect(await testData.getAll(), <String, dynamic>{
        'flutter.StringList': <String>['foo', 'bar'],
      });

      expect(log, hasLength(4));
      for (final MethodCall call in log) {
        expect(call.method, 'remove');
      }
    });

    test('setValue', () async {
      store = SharedPreferencesAndroid();
      expect(await testData.getAll(), isEmpty);
      for (final String key in kTestValues.keys) {
        final Object value = kTestValues[key]!;
        expect(await store.setValue(key.split('.').last, key, value), true);
      }
      expect(await testData.getAll(), kTestValues);

      expect(log, hasLength(5));
      expect(log[0].method, 'setString');
      expect(log[1].method, 'setBool');
      expect(log[2].method, 'setInt');
      expect(log[3].method, 'setDouble');
      expect(log[4].method, 'setStringList');
    });

    test('clear', () async {
      store = SharedPreferencesAndroid();
      testData = InMemorySharedPreferencesStore.withData(kTestValues);
      expect(await testData.getAll(), isNotEmpty);
      expect(await store.clear(), true);
      expect(await testData.getAll(), isEmpty);
      expect(log.single.method, 'clear');
    });
  });
}
