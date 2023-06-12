// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences_linux/shared_preferences_linux.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  late MemoryFileSystem fs;
  late PathProviderLinux pathProvider;

  SharedPreferencesLinux.registerWith();

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
    fs = MemoryFileSystem.test();
    pathProvider = FakePathProviderLinux();
  });

  Future<String> getFilePath() async {
    final String? directory = await pathProvider.getApplicationSupportPath();
    return path.join(directory!, 'shared_preferences.json');
  }

  Future<void> writeTestFile(String value) async {
    fs.file(await getFilePath())
      ..createSync(recursive: true)
      ..writeAsStringSync(value);
  }

  Future<String> readTestFile() async {
    return fs.file(await getFilePath()).readAsStringSync();
  }

  SharedPreferencesLinux getPreferences() {
    final SharedPreferencesLinux prefs = SharedPreferencesLinux();
    prefs.fs = fs;
    prefs.pathProvider = pathProvider;
    return prefs;
  }

  test('registered instance', () {
    SharedPreferencesLinux.registerWith();
    expect(
        SharedPreferencesStorePlatform.instance, isA<SharedPreferencesLinux>());
  });

  test('getAll', () async {
    await writeTestFile(json.encode(allTestValues));
    final SharedPreferencesLinux prefs = getPreferences();

    final Map<String, Object> values = await prefs.getAll();
    expect(values, hasLength(5));
    expect(values, flutterTestValues);
  });

  test('getAllWithPrefix', () async {
    await writeTestFile(json.encode(allTestValues));
    final SharedPreferencesLinux prefs = getPreferences();

    final Map<String, Object> values = await prefs.getAllWithPrefix('prefix.');
    expect(values, hasLength(5));
    expect(values, prefixTestValues);
  });

  test('remove', () async {
    await writeTestFile('{"key1":"one","key2":2}');
    final SharedPreferencesLinux prefs = getPreferences();

    await prefs.remove('key2');

    expect(await readTestFile(), '{"key1":"one"}');
  });

  test('setValue', () async {
    await writeTestFile('{}');
    final SharedPreferencesLinux prefs = getPreferences();

    await prefs.setValue('', 'key1', 'one');
    await prefs.setValue('', 'key2', 2);

    expect(await readTestFile(), '{"key1":"one","key2":2}');
  });

  test('clear', () async {
    await writeTestFile(json.encode(flutterTestValues));
    final SharedPreferencesLinux prefs = getPreferences();

    expect(await readTestFile(), json.encode(flutterTestValues));
    await prefs.clear();
    expect(await readTestFile(), '{}');
  });

  test('clearWithPrefix', () async {
    await writeTestFile(json.encode(flutterTestValues));
    final SharedPreferencesLinux prefs = getPreferences();
    await prefs.clearWithPrefix('prefix.');
    final Map<String, Object> noValues =
        await prefs.getAllWithPrefix('prefix.');
    expect(noValues, hasLength(0));

    final Map<String, Object> values = await prefs.getAll();
    expect(values, hasLength(5));
    expect(values, flutterTestValues);
  });

  test('getAllWithNoPrefix', () async {
    await writeTestFile(json.encode(allTestValues));
    final SharedPreferencesLinux prefs = getPreferences();

    final Map<String, Object> values = await prefs.getAllWithPrefix('');
    expect(values, hasLength(15));
    expect(values, allTestValues);
  });

  test('clearWithNoPrefix', () async {
    await writeTestFile(json.encode(flutterTestValues));
    final SharedPreferencesLinux prefs = getPreferences();
    await prefs.clearWithPrefix('');
    final Map<String, Object> noValues = await prefs.getAllWithPrefix('');
    expect(noValues, hasLength(0));
  });
}

/// Fake implementation of PathProviderLinux that returns hard-coded paths,
/// allowing tests to run on any platform.
///
/// Note that this should only be used with an in-memory filesystem, as the
/// path it returns is a root path that does not actually exist on Linux.
class FakePathProviderLinux extends PathProviderPlatform
    implements PathProviderLinux {
  @override
  Future<String?> getApplicationSupportPath() async => r'/appsupport';

  @override
  Future<String?> getTemporaryPath() async => null;

  @override
  Future<String?> getLibraryPath() async => null;

  @override
  Future<String?> getApplicationDocumentsPath() async => null;

  @override
  Future<String?> getDownloadsPath() async => null;
}
