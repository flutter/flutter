// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_foundation/shared_preferences_foundation.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'test_api.g.dart';

class _MockSharedPreferencesApi implements TestUserDefaultsApi {
  final Map<String, Object> items = <String, Object>{};

  @override
  Map<String?, Object?> getAllWithPrefix(String prefix) {
    return <String?, Object?>{
      for (final String key in items.keys)
        if (key.startsWith(prefix)) key: items[key]
    };
  }

  @override
  void remove(String key) {
    items.remove(key);
  }

  @override
  void setBool(String key, bool value) {
    items[key] = value;
  }

  @override
  void setDouble(String key, double value) {
    items[key] = value;
  }

  @override
  void setValue(String key, Object value) {
    items[key] = value;
  }

  @override
  void clearWithPrefix(String prefix) {
    items.keys.toList().forEach((String key) {
      if (key.startsWith(prefix)) {
        items.remove(key);
      }
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockSharedPreferencesApi api;

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

  setUp(() {
    api = _MockSharedPreferencesApi();
    TestUserDefaultsApi.setup(api);
  });

  test('registerWith', () {
    SharedPreferencesFoundation.registerWith();
    expect(SharedPreferencesStorePlatform.instance,
        isA<SharedPreferencesFoundation>());
  });

  test('remove', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    api.items['flutter.hi'] = 'world';
    expect(await plugin.remove('flutter.hi'), isTrue);
    expect(api.items.containsKey('flutter.hi'), isFalse);
  });

  test('clear', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    api.items['flutter.hi'] = 'world';
    expect(await plugin.clear(), isTrue);
    expect(api.items.containsKey('flutter.hi'), isFalse);
  });

  test('clearWithPrefix', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    for (final String key in allTestValues.keys) {
      api.items[key] = allTestValues[key]!;
    }

    Map<String?, Object?> all = await plugin.getAllWithPrefix('prefix.');
    expect(all.length, 5);
    await plugin.clearWithPrefix('prefix.');
    all = await plugin.getAll();
    expect(all.length, 5);
    all = await plugin.getAllWithPrefix('prefix.');
    expect(all.length, 0);
  });

  test('getAll', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    for (final String key in flutterTestValues.keys) {
      api.items[key] = flutterTestValues[key]!;
    }
    final Map<String?, Object?> all = await plugin.getAll();
    expect(all.length, 5);
    expect(all, flutterTestValues);
  });

  test('getAllWithPrefix', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    for (final String key in allTestValues.keys) {
      api.items[key] = allTestValues[key]!;
    }
    final Map<String?, Object?> all = await plugin.getAllWithPrefix('prefix.');
    expect(all.length, 5);
    expect(all, prefixTestValues);
  });

  test('setValue', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    expect(await plugin.setValue('Bool', 'flutter.Bool', true), isTrue);
    expect(api.items['flutter.Bool'], true);
    expect(await plugin.setValue('Double', 'flutter.Double', 1.5), isTrue);
    expect(api.items['flutter.Double'], 1.5);
    expect(await plugin.setValue('Int', 'flutter.Int', 12), isTrue);
    expect(api.items['flutter.Int'], 12);
    expect(await plugin.setValue('String', 'flutter.String', 'hi'), isTrue);
    expect(api.items['flutter.String'], 'hi');
    expect(
        await plugin
            .setValue('StringList', 'flutter.StringList', <String>['hi']),
        isTrue);
    expect(api.items['flutter.StringList'], <String>['hi']);
  });

  test('setValue with unsupported type', () {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    expect(() async {
      await plugin.setValue('Map', 'flutter.key', <String, String>{});
    }, throwsA(isA<PlatformException>()));
  });

  test('getAllWithNoPrefix', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    for (final String key in allTestValues.keys) {
      api.items[key] = allTestValues[key]!;
    }
    final Map<String?, Object?> all = await plugin.getAllWithPrefix('');
    expect(all.length, 15);
    expect(all, allTestValues);
  });

  test('clearWithNoPrefix', () async {
    final SharedPreferencesFoundation plugin = SharedPreferencesFoundation();
    for (final String key in allTestValues.keys) {
      api.items[key] = allTestValues[key]!;
    }

    Map<String?, Object?> all = await plugin.getAllWithPrefix('');
    expect(all.length, 15);
    await plugin.clearWithPrefix('');
    all = await plugin.getAllWithPrefix('');
    expect(all.length, 0);
  });
}
