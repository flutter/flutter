// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/windows.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
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
      environment = Environment.test(
        globals.fs.currentDirectory,
      );
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_export.h').createSync(recursive: true);
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_messenger.h').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.exp').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.lib').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.pdb').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\lutter_export.h').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_messenger.h').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_plugin_registrar.h').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.h').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\icudtl.dat').createSync();
      globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\cpp_client_wrapper\foo').createSync(recursive: true);
      globals.fs.file(r'C:\packages\flutter_tools\lib\src\build_system\targets\windows.dart').createSync(recursive: true);
      globals.fs.directory('windows').createSync();
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
    });
  });

  test('Copies files to correct cache directory', () => testbed.run(() async {
    await buildSystem.build(const UnpackWindows(), environment);

    expect(globals.fs.file(r'C:\windows\flutter\flutter_export.h').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_messenger.h').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_windows.dll').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_windows.dll.exp').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_windows.dll.lib').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_windows.dll.pdb').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_export.h').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_messenger.h').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_plugin_registrar.h').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\flutter_windows.h').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\icudtl.dat').existsSync(), true);
    expect(globals.fs.file(r'C:\windows\flutter\cpp_client_wrapper\foo').existsSync(), true);
  }));

  test('Does not re-copy files unecessarily', () => testbed.run(() async {
    await buildSystem.build(const UnpackWindows(), environment);
    // Set a date in the far distant past to deal with the limited resolution
    // of the windows filesystem.
    final DateTime theDistantPast = DateTime(1991, 8, 23);
    globals.fs.file(r'C:\windows\flutter\flutter_export.h').setLastModifiedSync(theDistantPast);
    await buildSystem.build(const UnpackWindows(), environment);

    expect(globals.fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified, equals(theDistantPast));
  }));

  test('Detects changes in input cache files', () => testbed.run(() async {
    await buildSystem.build(const UnpackWindows(), environment);
    // Set a date in the far distant past to deal with the limited resolution
    // of the windows filesystem.
    final DateTime theDistantPast = DateTime(1991, 8, 23);
    globals.fs.file(r'C:\windows\flutter\flutter_export.h').setLastModifiedSync(theDistantPast);
    final DateTime modified = globals.fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified;
    globals.fs.file(r'C:\bin\cache\artifacts\engine\windows-x64\flutter_export.h').writeAsStringSync('asd'); // modify cache.

    await buildSystem.build(const UnpackWindows(), environment);

    expect(globals.fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified, isNot(modified));
  }));
}

class MockPlatform extends Mock implements Platform {}
