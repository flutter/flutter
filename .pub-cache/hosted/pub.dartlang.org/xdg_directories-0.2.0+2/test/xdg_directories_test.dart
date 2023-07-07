// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

void main() {
  final Map<String, String> fakeEnv = <String, String>{};
  late Directory tmpDir;

  String testRootPath() {
    final String basePath = tmpDir.path;
    return Platform.isWindows
        // Strip the drive specifier when running tests on Windows since
        // environment variables use : as a path list separator.
        ? basePath.substring(basePath.indexOf(':') + 1)
        : basePath;
  }

  String testPath(String subdir) => path.join(testRootPath(), subdir);

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('xdg_test');
    fakeEnv.clear();
    fakeEnv['HOME'] = testRootPath();
    fakeEnv['XDG_CACHE_HOME'] = testPath('.test_cache');
    fakeEnv['XDG_CONFIG_DIRS'] = testPath('etc/test_xdg');
    fakeEnv['XDG_CONFIG_HOME'] = testPath('.test_config');
    fakeEnv['XDG_DATA_DIRS'] =
        '${testPath('usr/local/test_share')}:${testPath('usr/test_share')}';
    fakeEnv['XDG_DATA_HOME'] = testPath('.local/test_share');
    fakeEnv['XDG_RUNTIME_DIR'] = testPath('.local/test_runtime');
    Directory(fakeEnv['XDG_CONFIG_HOME']!).createSync(recursive: true);
    Directory(fakeEnv['XDG_CACHE_HOME']!).createSync(recursive: true);
    Directory(fakeEnv['XDG_DATA_HOME']!).createSync(recursive: true);
    Directory(fakeEnv['XDG_RUNTIME_DIR']!).createSync(recursive: true);
    File(path.join(fakeEnv['XDG_CONFIG_HOME']!, 'user-dirs.dirs'))
        .writeAsStringSync(r'''
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_VIDEOS_DIR="$HOME/Videos"
''');
    xdg.xdgEnvironmentOverride = (String key) => fakeEnv[key];
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
    // Stop overriding the environment accessor.
    xdg.xdgEnvironmentOverride = null;
  });
  void expectDirList(List<Directory> values, List<String> expected) {
    final List<String> valueStr =
        values.map<String>((Directory directory) => directory.path).toList();
    expect(valueStr, orderedEquals(expected));
  }

  test('Default fallback values work', () {
    fakeEnv.clear();
    fakeEnv['HOME'] = testRootPath();
    expect(xdg.cacheHome.path, equals(testPath('.cache')));
    expect(xdg.configHome.path, equals(testPath('.config')));
    expect(xdg.dataHome.path, equals(testPath('.local/share')));
    expect(xdg.runtimeDir, isNull);

    expectDirList(xdg.configDirs, <String>['/etc/xdg']);
    expectDirList(xdg.dataDirs, <String>['/usr/local/share', '/usr/share']);
  });

  test('Values pull from environment', () {
    expect(xdg.cacheHome.path, equals(testPath('.test_cache')));
    expect(xdg.configHome.path, equals(testPath('.test_config')));
    expect(xdg.dataHome.path, equals(testPath('.local/test_share')));
    expect(xdg.runtimeDir, isNotNull);
    expect(xdg.runtimeDir!.path, equals(testPath('.local/test_runtime')));

    expectDirList(xdg.configDirs, <String>[testPath('etc/test_xdg')]);
    expectDirList(xdg.dataDirs, <String>[
      testPath('usr/local/test_share'),
      testPath('usr/test_share'),
    ]);
  });

  test('Can get userDirs', () {
    final Map<String, String> expected = <String, String>{
      'DESKTOP': testPath('Desktop'),
      'DOCUMENTS': testPath('Documents'),
      'DOWNLOAD': testPath('Downloads'),
      'MUSIC': testPath('Music'),
      'PICTURES': testPath('Pictures'),
      'PUBLICSHARE': testPath('Public'),
      'TEMPLATES': testPath('Templates'),
      'VIDEOS': testPath('Videos'),
    };
    xdg.xdgProcessManager = FakeProcessManager(expected);
    final Set<String> userDirs = xdg.getUserDirectoryNames();
    expect(userDirs, equals(expected.keys.toSet()));
    for (final String key in userDirs) {
      expect(xdg.getUserDirectory(key)!.path, equals(expected[key]),
          reason: 'Path $key value not correct');
    }
    xdg.xdgProcessManager = const LocalProcessManager();
  });

  test('Throws StateError when HOME not set', () {
    fakeEnv.clear();
    expect(() {
      xdg.configHome;
    }, throwsStateError);
  });
}

class FakeProcessManager extends Fake implements ProcessManager {
  FakeProcessManager(this.expected);

  Map<String, String> expected;

  @override
  ProcessResult runSync(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    return ProcessResult(0, 0, expected[command[1]], '');
  }
}
