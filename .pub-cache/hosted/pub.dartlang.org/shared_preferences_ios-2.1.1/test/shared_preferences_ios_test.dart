// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'messages.g.dart';

class _MockSharedPreferencesApi implements TestUserDefaultsApi {
  final Map<String, Object> items = <String, Object>{};

  @override
  Map<String?, Object?> getAll() {
    return items;
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
  void clear() {
    items.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _MockSharedPreferencesApi api = _MockSharedPreferencesApi();
  SharedPreferencesIOS plugin = SharedPreferencesIOS();

  setUp(() {
    api = _MockSharedPreferencesApi();
    TestUserDefaultsApi.setup(api);
    plugin = SharedPreferencesIOS();
  });

  test('registerWith', () {
    SharedPreferencesIOS.registerWith();
    expect(
        SharedPreferencesStorePlatform.instance, isA<SharedPreferencesIOS>());
  });

  test('remove', () async {
    api.items['flutter.hi'] = 'world';
    expect(await plugin.remove('flutter.hi'), isTrue);
    expect(api.items.containsKey('flutter.hi'), isFalse);
  });

  test('clear', () async {
    api.items['flutter.hi'] = 'world';
    expect(await plugin.clear(), isTrue);
    expect(api.items.containsKey('flutter.hi'), isFalse);
  });

  test('getAll', () async {
    api.items['flutter.hi'] = 'world';
    api.items['flutter.bye'] = 'dust';
    final Map<String?, Object?> all = await plugin.getAll();
    expect(all.length, 2);
    expect(all['flutter.hi'], api.items['flutter.hi']);
    expect(all['flutter.bye'], api.items['flutter.bye']);
  });

  test('setValue', () async {
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
    expect(() async {
      await plugin.setValue('Map', 'flutter.key', <String, String>{});
    }, throwsA(isA<PlatformException>()));
  });
}
