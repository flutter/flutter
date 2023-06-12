// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferences', () {
    const String testString = 'hello world';
    const bool testBool = true;
    const int testInt = 42;
    const double testDouble = 3.14159;
    const List<String> testList = <String>['foo', 'bar'];
    const Map<String, Object> testValues = <String, Object>{
      'flutter.String': testString,
      'flutter.bool': testBool,
      'flutter.int': testInt,
      'flutter.double': testDouble,
      'flutter.List': testList,
    };

    const String testString2 = 'goodbye world';
    const bool testBool2 = false;
    const int testInt2 = 1337;
    const double testDouble2 = 2.71828;
    const List<String> testList2 = <String>['baz', 'quox'];
    const Map<String, dynamic> testValues2 = <String, dynamic>{
      'flutter.String': testString2,
      'flutter.bool': testBool2,
      'flutter.int': testInt2,
      'flutter.double': testDouble2,
      'flutter.List': testList2,
    };

    late FakeSharedPreferencesStore store;
    late SharedPreferences preferences;

    setUp(() async {
      store = FakeSharedPreferencesStore(testValues);
      SharedPreferencesStorePlatform.instance = store;
      preferences = await SharedPreferences.getInstance();
      store.log.clear();
    });

    test('reading', () async {
      expect(preferences.get('String'), testString);
      expect(preferences.get('bool'), testBool);
      expect(preferences.get('int'), testInt);
      expect(preferences.get('double'), testDouble);
      expect(preferences.get('List'), testList);
      expect(preferences.getString('String'), testString);
      expect(preferences.getBool('bool'), testBool);
      expect(preferences.getInt('int'), testInt);
      expect(preferences.getDouble('double'), testDouble);
      expect(preferences.getStringList('List'), testList);
      expect(store.log, <Matcher>[]);
    });

    test('writing', () async {
      await Future.wait(<Future<bool>>[
        preferences.setString('String', testString2),
        preferences.setBool('bool', testBool2),
        preferences.setInt('int', testInt2),
        preferences.setDouble('double', testDouble2),
        preferences.setStringList('List', testList2)
      ]);
      expect(
        store.log,
        <Matcher>[
          isMethodCall('setValue', arguments: <dynamic>[
            'String',
            'flutter.String',
            testString2,
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'Bool',
            'flutter.bool',
            testBool2,
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'Int',
            'flutter.int',
            testInt2,
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'Double',
            'flutter.double',
            testDouble2,
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'StringList',
            'flutter.List',
            testList2,
          ]),
        ],
      );
      store.log.clear();

      expect(preferences.getString('String'), testString2);
      expect(preferences.getBool('bool'), testBool2);
      expect(preferences.getInt('int'), testInt2);
      expect(preferences.getDouble('double'), testDouble2);
      expect(preferences.getStringList('List'), testList2);
      expect(store.log, equals(<MethodCall>[]));
    });

    test('removing', () async {
      const String key = 'testKey';
      await preferences.remove(key);
      expect(
          store.log,
          List<Matcher>.filled(
            1,
            isMethodCall(
              'remove',
              arguments: 'flutter.$key',
            ),
            growable: true,
          ));
    });

    test('containsKey', () async {
      const String key = 'testKey';

      expect(false, preferences.containsKey(key));

      await preferences.setString(key, 'test');
      expect(true, preferences.containsKey(key));
    });

    test('clearing', () async {
      await preferences.clear();
      expect(preferences.getString('String'), null);
      expect(preferences.getBool('bool'), null);
      expect(preferences.getInt('int'), null);
      expect(preferences.getDouble('double'), null);
      expect(preferences.getStringList('List'), null);
      expect(store.log, <Matcher>[isMethodCall('clear', arguments: null)]);
    });

    test('reloading', () async {
      await preferences.setString('String', testString);
      expect(preferences.getString('String'), testString);

      SharedPreferences.setMockInitialValues(
          testValues2.cast<String, Object>());
      expect(preferences.getString('String'), testString);

      await preferences.reload();
      expect(preferences.getString('String'), testString2);
    });

    test('back to back calls should return same instance.', () async {
      final Future<SharedPreferences> first = SharedPreferences.getInstance();
      final Future<SharedPreferences> second = SharedPreferences.getInstance();
      expect(await first, await second);
    });

    test('string list type is dynamic (usually from method channel)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dynamic_list': <dynamic>['1', '2']
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? value = prefs.getStringList('dynamic_list');
      expect(value, <String>['1', '2']);
    });

    group('mocking', () {
      const String _key = 'dummy';
      const String _prefixedKey = 'flutter.$_key';

      test('test 1', () async {
        SharedPreferences.setMockInitialValues(
            <String, Object>{_prefixedKey: 'my string'});
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? value = prefs.getString(_key);
        expect(value, 'my string');
      });

      test('test 2', () async {
        SharedPreferences.setMockInitialValues(
            <String, Object>{_prefixedKey: 'my other string'});
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? value = prefs.getString(_key);
        expect(value, 'my other string');
      });
    });

    test('writing copy of strings list', () async {
      final List<String> myList = <String>[];
      await preferences.setStringList('myList', myList);
      myList.add('foobar');

      final List<String> cachedList = preferences.getStringList('myList')!;
      expect(cachedList, <String>[]);

      cachedList.add('foobar2');

      expect(preferences.getStringList('myList'), <String>[]);
    });
  });

  test('calling mock initial values with non-prefixed keys succeeds', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'test': 'foo',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString('test');
    expect(value, 'foo');
  });
}

class FakeSharedPreferencesStore implements SharedPreferencesStorePlatform {
  FakeSharedPreferencesStore(Map<String, Object> data)
      : backend = InMemorySharedPreferencesStore.withData(data);

  final InMemorySharedPreferencesStore backend;
  final List<MethodCall> log = <MethodCall>[];

  @override
  bool get isMock => true;

  @override
  Future<bool> clear() {
    log.add(const MethodCall('clear'));
    return backend.clear();
  }

  @override
  Future<Map<String, Object>> getAll() {
    log.add(const MethodCall('getAll'));
    return backend.getAll();
  }

  @override
  Future<bool> remove(String key) {
    log.add(MethodCall('remove', key));
    return backend.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    log.add(MethodCall('setValue', <dynamic>[valueType, key, value]));
    return backend.setValue(valueType, key, value);
  }
}
