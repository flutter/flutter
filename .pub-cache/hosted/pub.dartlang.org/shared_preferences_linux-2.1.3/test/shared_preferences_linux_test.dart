// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
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
    await writeTestFile('{"key1": "one", "key2": 2}');
    final SharedPreferencesLinux prefs = getPreferences();

    final Map<String, Object> values = await prefs.getAll();
    expect(values, hasLength(2));
    expect(values['key1'], 'one');
    expect(values['key2'], 2);
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
    await writeTestFile('{"key1":"one","key2":2}');
    final SharedPreferencesLinux prefs = getPreferences();

    await prefs.clear();
    expect(await readTestFile(), '{}');
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
