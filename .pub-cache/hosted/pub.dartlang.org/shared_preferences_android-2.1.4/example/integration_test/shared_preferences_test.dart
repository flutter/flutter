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

    late SharedPreferencesStorePlatform preferences;

    setUp(() async {
      preferences = SharedPreferencesStorePlatform.instance;
    });

    tearDown(() {
      preferences.clearWithPrefix('');
    });

    testWidgets('reading', (WidgetTester _) async {
      final Map<String, Object> values = await preferences.getAllWithPrefix('');
      expect(values['String'], isNull);
      expect(values['Bool'], isNull);
      expect(values['Int'], isNull);
      expect(values['Double'], isNull);
      expect(values['StringList'], isNull);
    });

    testWidgets('getAllWithPrefix', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setValue(
            'String', 'prefix.String', allTestValues['prefix.String']!),
        preferences.setValue(
            'Bool', 'prefix.Bool', allTestValues['prefix.Bool']!),
        preferences.setValue('Int', 'prefix.Int', allTestValues['prefix.Int']!),
        preferences.setValue(
            'Double', 'prefix.Double', allTestValues['prefix.Double']!),
        preferences.setValue('StringList', 'prefix.StringList',
            allTestValues['prefix.StringList']!),
        preferences.setValue(
            'String', 'flutter.String', allTestValues['flutter.String']!),
        preferences.setValue(
            'Bool', 'flutter.Bool', allTestValues['flutter.Bool']!),
        preferences.setValue(
            'Int', 'flutter.Int', allTestValues['flutter.Int']!),
        preferences.setValue(
            'Double', 'flutter.Double', allTestValues['flutter.Double']!),
        preferences.setValue('StringList', 'flutter.StringList',
            allTestValues['flutter.StringList']!)
      ]);
      final Map<String, Object> values =
          await preferences.getAllWithPrefix('prefix.');
      expect(values['prefix.String'], allTestValues['prefix.String']);
      expect(values['prefix.Bool'], allTestValues['prefix.Bool']);
      expect(values['prefix.Int'], allTestValues['prefix.Int']);
      expect(values['prefix.Double'], allTestValues['prefix.Double']);
      expect(values['prefix.StringList'], allTestValues['prefix.StringList']);
    });

    testWidgets('clearWithPrefix', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setValue(
            'String', 'prefix.String', allTestValues['prefix.String']!),
        preferences.setValue(
            'Bool', 'prefix.Bool', allTestValues['prefix.Bool']!),
        preferences.setValue('Int', 'prefix.Int', allTestValues['prefix.Int']!),
        preferences.setValue(
            'Double', 'prefix.Double', allTestValues['prefix.Double']!),
        preferences.setValue('StringList', 'prefix.StringList',
            allTestValues['prefix.StringList']!),
        preferences.setValue(
            'String', 'flutter.String', allTestValues['flutter.String']!),
        preferences.setValue(
            'Bool', 'flutter.Bool', allTestValues['flutter.Bool']!),
        preferences.setValue(
            'Int', 'flutter.Int', allTestValues['flutter.Int']!),
        preferences.setValue(
            'Double', 'flutter.Double', allTestValues['flutter.Double']!),
        preferences.setValue('StringList', 'flutter.StringList',
            allTestValues['flutter.StringList']!)
      ]);
      await preferences.clearWithPrefix('prefix.');
      Map<String, Object> values =
          await preferences.getAllWithPrefix('prefix.');
      expect(values['prefix.String'], null);
      expect(values['prefix.Bool'], null);
      expect(values['prefix.Int'], null);
      expect(values['prefix.Double'], null);
      expect(values['prefix.StringList'], null);
      values = await preferences.getAllWithPrefix('flutter.');
      expect(values['flutter.String'], allTestValues['flutter.String']);
      expect(values['flutter.Bool'], allTestValues['flutter.Bool']);
      expect(values['flutter.Int'], allTestValues['flutter.Int']);
      expect(values['flutter.Double'], allTestValues['flutter.Double']);
      expect(values['flutter.StringList'], allTestValues['flutter.StringList']);
    });

    testWidgets('getAllWithNoPrefix', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setValue('String', 'String', allTestValues['String']!),
        preferences.setValue('Bool', 'Bool', allTestValues['Bool']!),
        preferences.setValue('Int', 'Int', allTestValues['Int']!),
        preferences.setValue('Double', 'Double', allTestValues['Double']!),
        preferences.setValue(
            'StringList', 'StringList', allTestValues['StringList']!),
        preferences.setValue(
            'String', 'flutter.String', allTestValues['flutter.String']!),
        preferences.setValue(
            'Bool', 'flutter.Bool', allTestValues['flutter.Bool']!),
        preferences.setValue(
            'Int', 'flutter.Int', allTestValues['flutter.Int']!),
        preferences.setValue(
            'Double', 'flutter.Double', allTestValues['flutter.Double']!),
        preferences.setValue('StringList', 'flutter.StringList',
            allTestValues['flutter.StringList']!)
      ]);
      final Map<String, Object> values = await preferences.getAllWithPrefix('');
      expect(values['String'], allTestValues['String']);
      expect(values['Bool'], allTestValues['Bool']);
      expect(values['Int'], allTestValues['Int']);
      expect(values['Double'], allTestValues['Double']);
      expect(values['StringList'], allTestValues['StringList']);
      expect(values['flutter.String'], allTestValues['flutter.String']);
      expect(values['flutter.Bool'], allTestValues['flutter.Bool']);
      expect(values['flutter.Int'], allTestValues['flutter.Int']);
      expect(values['flutter.Double'], allTestValues['flutter.Double']);
      expect(values['flutter.StringList'], allTestValues['flutter.StringList']);
    });

    testWidgets('clearWithNoPrefix', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setValue('String', 'String', allTestValues['String']!),
        preferences.setValue('Bool', 'Bool', allTestValues['Bool']!),
        preferences.setValue('Int', 'Int', allTestValues['Int']!),
        preferences.setValue('Double', 'Double', allTestValues['Double']!),
        preferences.setValue(
            'StringList', 'StringList', allTestValues['StringList']!),
        preferences.setValue(
            'String', 'flutter.String', allTestValues['flutter.String']!),
        preferences.setValue(
            'Bool', 'flutter.Bool', allTestValues['flutter.Bool']!),
        preferences.setValue(
            'Int', 'flutter.Int', allTestValues['flutter.Int']!),
        preferences.setValue(
            'Double', 'flutter.Double', allTestValues['flutter.Double']!),
        preferences.setValue('StringList', 'flutter.StringList',
            allTestValues['flutter.StringList']!)
      ]);
      await preferences.clearWithPrefix('');
      final Map<String, Object> values = await preferences.getAllWithPrefix('');
      expect(values['String'], null);
      expect(values['Bool'], null);
      expect(values['Int'], null);
      expect(values['Double'], null);
      expect(values['StringList'], null);
      expect(values['flutter.String'], null);
      expect(values['flutter.Bool'], null);
      expect(values['flutter.Int'], null);
      expect(values['flutter.Double'], null);
      expect(values['flutter.StringList'], null);
    });

    testWidgets('getAll', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setValue(
            'String', 'flutter.String', allTestValues['flutter.String']!),
        preferences.setValue(
            'Bool', 'flutter.Bool', allTestValues['flutter.Bool']!),
        preferences.setValue(
            'Int', 'flutter.Int', allTestValues['flutter.Int']!),
        preferences.setValue(
            'Double', 'flutter.Double', allTestValues['flutter.Double']!),
        preferences.setValue('StringList', 'flutter.StringList',
            allTestValues['flutter.StringList']!)
      ]);
      final Map<String, Object> values = await preferences.getAll();
      expect(values['flutter.String'], allTestValues['flutter.String']);
      expect(values['flutter.Bool'], allTestValues['flutter.Bool']);
      expect(values['flutter.Int'], allTestValues['flutter.Int']);
      expect(values['flutter.Double'], allTestValues['flutter.Double']);
      expect(values['flutter.StringList'], allTestValues['flutter.StringList']);
    });

    testWidgets('remove', (WidgetTester _) async {
      const String key = 'testKey';
      await preferences.setValue(
          'String', key, allTestValues['flutter.String']!);
      await preferences.setValue('Bool', key, allTestValues['flutter.Bool']!);
      await preferences.setValue('Int', key, allTestValues['flutter.Int']!);
      await preferences.setValue(
          'Double', key, allTestValues['flutter.Double']!);
      await preferences.setValue(
          'StringList', key, allTestValues['flutter.StringList']!);
      await preferences.remove(key);
      final Map<String, Object> values = await preferences.getAllWithPrefix('');
      expect(values[key], isNull);
    });

    testWidgets('clear', (WidgetTester _) async {
      await preferences.setValue(
          'String', 'flutter.String', allTestValues['flutter.String']!);
      await preferences.setValue(
          'Bool', 'flutter.Bool', allTestValues['flutter.Bool']!);
      await preferences.setValue(
          'Int', 'flutter.Int', allTestValues['flutter.Int']!);
      await preferences.setValue(
          'Double', 'flutter.Double', allTestValues['flutter.Double']!);
      await preferences.setValue('StringList', 'flutter.StringList',
          allTestValues['flutter.StringList']!);
      await preferences.clear();
      final Map<String, Object> values = await preferences.getAll();
      expect(values['flutter.String'], null);
      expect(values['flutter.Bool'], null);
      expect(values['flutter.Int'], null);
      expect(values['flutter.Double'], null);
      expect(values['flutter.StringList'], null);
    });

    testWidgets('simultaneous writes', (WidgetTester _) async {
      final List<Future<bool>> writes = <Future<bool>>[];
      const int writeCount = 100;
      for (int i = 1; i <= writeCount; i++) {
        writes.add(preferences.setValue('Int', 'Int', i));
      }
      final List<bool> result = await Future.wait(writes, eagerError: true);
      // All writes should succeed.
      expect(result.where((bool element) => !element), isEmpty);
      // The last write should win.
      final Map<String, Object> values = await preferences.getAllWithPrefix('');
      expect(values['Int'], writeCount);
    });

    testWidgets('string clash with lists, big integers and doubles',
        (WidgetTester _) async {
      const String key = 'akey';
      const String value = 'a string value';
      await preferences.clearWithPrefix('');

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
        final Map<String, Object> values =
            await preferences.getAllWithPrefix('');
        expect(values[key], null);
      }
    });
  });
}
