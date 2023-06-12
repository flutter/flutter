// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('$SharedPreferences', () {
    const String testString = 'hello world';
    const bool testBool = true;
    const int testInt = 42;
    const double testDouble = 3.14159;
    const List<String> testList = <String>['foo', 'bar'];

    const String testString2 = 'goodbye world';
    const bool testBool2 = false;
    const int testInt2 = 1337;
    const double testDouble2 = 2.71828;
    const List<String> testList2 = <String>['baz', 'quox'];

    late SharedPreferences preferences;

    setUp(() async {
      preferences = await SharedPreferences.getInstance();
    });

    tearDown(() {
      preferences.clear();
    });

    testWidgets('reading', (WidgetTester _) async {
      expect(preferences.get('String'), isNull);
      expect(preferences.get('bool'), isNull);
      expect(preferences.get('int'), isNull);
      expect(preferences.get('double'), isNull);
      expect(preferences.get('List'), isNull);
      expect(preferences.getString('String'), isNull);
      expect(preferences.getBool('bool'), isNull);
      expect(preferences.getInt('int'), isNull);
      expect(preferences.getDouble('double'), isNull);
      expect(preferences.getStringList('List'), isNull);
    });

    testWidgets('writing', (WidgetTester _) async {
      await Future.wait(<Future<bool>>[
        preferences.setString('String', testString2),
        preferences.setBool('bool', testBool2),
        preferences.setInt('int', testInt2),
        preferences.setDouble('double', testDouble2),
        preferences.setStringList('List', testList2)
      ]);
      expect(preferences.getString('String'), testString2);
      expect(preferences.getBool('bool'), testBool2);
      expect(preferences.getInt('int'), testInt2);
      expect(preferences.getDouble('double'), testDouble2);
      expect(preferences.getStringList('List'), testList2);
    });

    testWidgets('removing', (WidgetTester _) async {
      const String key = 'testKey';
      await preferences.setString(key, testString);
      await preferences.setBool(key, testBool);
      await preferences.setInt(key, testInt);
      await preferences.setDouble(key, testDouble);
      await preferences.setStringList(key, testList);
      await preferences.remove(key);
      expect(preferences.get('testKey'), isNull);
    });

    testWidgets('clearing', (WidgetTester _) async {
      await preferences.setString('String', testString);
      await preferences.setBool('bool', testBool);
      await preferences.setInt('int', testInt);
      await preferences.setDouble('double', testDouble);
      await preferences.setStringList('List', testList);
      await preferences.clear();
      expect(preferences.getString('String'), null);
      expect(preferences.getBool('bool'), null);
      expect(preferences.getInt('int'), null);
      expect(preferences.getDouble('double'), null);
      expect(preferences.getStringList('List'), null);
    });

    testWidgets('simultaneous writes', (WidgetTester _) async {
      final List<Future<bool>> writes = <Future<bool>>[];
      const int writeCount = 100;
      for (int i = 1; i <= writeCount; i++) {
        writes.add(preferences.setInt('int', i));
      }
      final List<bool> result = await Future.wait(writes, eagerError: true);
      // All writes should succeed.
      expect(result.where((bool element) => !element), isEmpty);
      // The last write should win.
      expect(preferences.getInt('int'), writeCount);
    });
  });
}
