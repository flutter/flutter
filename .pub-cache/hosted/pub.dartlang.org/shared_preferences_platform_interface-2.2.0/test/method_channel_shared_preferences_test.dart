// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(MethodChannelSharedPreferencesStore, () {
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );

    const Map<String, Object> flutterTestValues = <String, Object>{
      'flutter.String': 'hello world',
      'flutter.Bool': true,
      'flutter.Int': 42,
      'flutter.Double': 3.14159,
      'flutter.StringList': <String>['foo', 'bar'],
    };

    const Map<String, Object> prefixTestValues = <String, Object>{
      'prefix.String': 'hello world',
      'prefix.Bool': true,
      'prefix.Int': 42,
      'prefix.Double': 3.14159,
      'prefix.StringList': <String>['foo', 'bar'],
    };

    const Map<String, Object> nonPrefixTestValues = <String, Object>{
      'String': 'hello world',
      'Bool': true,
      'Int': 42,
      'Double': 3.14159,
      'StringList': <String>['foo', 'bar'],
    };

    final Map<String, Object> allTestValues = <String, Object>{};

    allTestValues.addAll(flutterTestValues);
    allTestValues.addAll(prefixTestValues);
    allTestValues.addAll(nonPrefixTestValues);

    late InMemorySharedPreferencesStore testData;

    final List<MethodCall> log = <MethodCall>[];
    late MethodChannelSharedPreferencesStore store;

    setUp(() async {
      testData = InMemorySharedPreferencesStore.empty();

      Map<String, Object?> getArgumentDictionary(MethodCall call) {
        return (call.arguments as Map<Object?, Object?>)
            .cast<String, Object?>();
      }

      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
          .defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'getAll') {
          return testData.getAll();
        }
        if (methodCall.method == 'getAllWithPrefix') {
          final Map<String, Object?> arguments =
              getArgumentDictionary(methodCall);
          final String prefix = arguments['prefix']! as String;
          return testData.getAllWithPrefix(prefix);
        }
        if (methodCall.method == 'remove') {
          final Map<String, Object?> arguments =
              getArgumentDictionary(methodCall);
          final String key = arguments['key']! as String;
          return testData.remove(key);
        }
        if (methodCall.method == 'clear') {
          return testData.clear();
        }
        if (methodCall.method == 'clearWithPrefix') {
          final Map<String, Object?> arguments =
              getArgumentDictionary(methodCall);
          final String prefix = arguments['prefix']! as String;
          return testData.clearWithPrefix(prefix);
        }
        final RegExp setterRegExp = RegExp(r'set(.*)');
        final Match? match = setterRegExp.matchAsPrefix(methodCall.method);
        if (match?.groupCount == 1) {
          final String valueType = match!.group(1)!;
          final Map<String, Object?> arguments =
              getArgumentDictionary(methodCall);
          final String key = arguments['key']! as String;
          final Object value = arguments['value']!;
          return testData.setValue(valueType, key, value);
        }
        fail('Unexpected method call: ${methodCall.method}');
      });
      store = MethodChannelSharedPreferencesStore();
      log.clear();
    });

    tearDown(() async {
      await testData.clear();
    });

    test('getAll', () async {
      testData = InMemorySharedPreferencesStore.withData(allTestValues);
      expect(await store.getAll(), flutterTestValues);
      expect(log.single.method, 'getAll');
    });

    test('getAllWithPrefix', () async {
      testData = InMemorySharedPreferencesStore.withData(allTestValues);
      expect(await store.getAllWithPrefix('prefix.'), prefixTestValues);
      expect(log.single.method, 'getAllWithPrefix');
    });

    test('remove', () async {
      testData = InMemorySharedPreferencesStore.withData(allTestValues);
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
      expect(await testData.getAll(), isEmpty);
      for (final String key in allTestValues.keys) {
        final Object value = allTestValues[key]!;
        expect(await store.setValue(key.split('.').last, key, value), true);
      }
      expect(await testData.getAll(), flutterTestValues);

      expect(log, hasLength(15));
      expect(log[0].method, 'setString');
      expect(log[1].method, 'setBool');
      expect(log[2].method, 'setInt');
      expect(log[3].method, 'setDouble');
      expect(log[4].method, 'setStringList');
    });

    test('clear', () async {
      testData = InMemorySharedPreferencesStore.withData(allTestValues);
      expect(await testData.getAll(), isNotEmpty);
      expect(await store.clear(), true);
      expect(await testData.getAll(), isEmpty);
      expect(log.single.method, 'clear');
    });

    test('clearWithPrefix', () async {
      testData = InMemorySharedPreferencesStore.withData(allTestValues);

      expect(await testData.getAllWithPrefix('prefix.'), isNotEmpty);
      expect(await store.clearWithPrefix('prefix.'), true);
      expect(await testData.getAllWithPrefix('prefix.'), isEmpty);
    });

    test('getAllWithNoPrefix', () async {
      testData = InMemorySharedPreferencesStore.withData(allTestValues);

      expect(await testData.getAllWithPrefix(''), hasLength(15));
    });

    test('clearWithNoPrefix', () async {
      testData = InMemorySharedPreferencesStore.withData(allTestValues);

      expect(await testData.getAllWithPrefix(''), isNotEmpty);
      expect(await store.clearWithPrefix(''), true);
      expect(await testData.getAllWithPrefix(''), isEmpty);
    });
  });
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
T? _ambiguate<T>(T? value) => value;
