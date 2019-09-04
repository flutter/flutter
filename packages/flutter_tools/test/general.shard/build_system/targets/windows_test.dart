// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/windows.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/testbed.dart';

void main() {
  Testbed testbed;
  const BuildSystem buildSystem = BuildSystem();
  Environment environment;
  Platform platform;

  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = '';
  });

  setUp(() {
    platform = MockPlatform();
    when(platform.isWindows).thenReturn(true);
    when(platform.isMacOS).thenReturn(false);
    when(platform.isLinux).thenReturn(false);
    when(platform.pathSeparator).thenReturn(r'\');
    testbed = Testbed(setup: () {
      environment = Environment(
        outputDir: fs.currentDirectory,
        projectDir: fs.currentDirectory,
      );
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_export.h').createSync(recursive: true);
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_messenger.h').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.exp').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.lib').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.pdb').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\lutter_export.h').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_messenger.h').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_plugin_registrar.h').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.h').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\icudtl.dat').createSync();
      fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\cpp_client_wrapper\foo').createSync(recursive: true);
      fs.file(r'C:\packages\flutter_tools\lib\src\build_system\targets\windows.dart').createSync(recursive: true);
      fs.directory('windows').createSync();
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
      Platform: () => platform,
    });
  });

  test('Copies files to correct cache directory', () => testbed.run(() async {
    await buildSystem.build(const UnpackWindows(), environment);

    expect(fs.file(r'C:\windows\flutter\flutter_export.h').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_messenger.h').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_windows.dll').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_windows.dll.exp').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_windows.dll.lib').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_windows.dll.pdb').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_export.h').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_messenger.h').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_plugin_registrar.h').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\flutter_windows.h').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\icudtl.dat').existsSync(), true);
    expect(fs.file(r'C:\windows\flutter\cpp_client_wrapper\foo').existsSync(), true);
  }));

  test('Does not re-copy files unecessarily', () => testbed.run(() async {
    await buildSystem.build(const UnpackWindows(), environment);
    // Set a date in the far distant past to deal with the limited resolution
    // of the windows filesystem.
    final DateTime theDistantPast = DateTime(1991, 8, 23);
    fs.file(r'C:\windows\flutter\flutter_export.h').setLastModifiedSync(theDistantPast);
    await buildSystem.build(const UnpackWindows(), environment);

    expect(fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified, equals(theDistantPast));
  }));

  test('Detects changes in input cache files', () => testbed.run(() async {
    await buildSystem.build(const UnpackWindows(), environment);
    // Set a date in the far distant past to deal with the limited resolution
    // of the windows filesystem.
    final DateTime theDistantPast = DateTime(1991, 8, 23);
    fs.file(r'C:\windows\flutter\flutter_export.h').setLastModifiedSync(theDistantPast);
    final DateTime modified = fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified;
    fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_export.h').writeAsStringSync('asd'); // modify cache.

    await buildSystem.build(const UnpackWindows(), environment);

    expect(fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified, isNot(modified));
  }));
}

class MockPlatform extends Mock implements Platform {}
