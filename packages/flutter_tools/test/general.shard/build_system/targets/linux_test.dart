// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/linux.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/testbed.dart';

void main() {
  Testbed testbed;
  const BuildSystem buildSystem = BuildSystem();
  Environment environment;
  MockPlatform mockPlatform;

  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = '';
  });

  setUp(() {
    mockPlatform = MockPlatform();
    when(mockPlatform.isWindows).thenReturn(false);
    when(mockPlatform.isMacOS).thenReturn(false);
    when(mockPlatform.isLinux).thenReturn(true);
    testbed = Testbed(setup: () {
      Cache.flutterRoot = '';
      environment = Environment(
        projectDir: fs.currentDirectory,
      );
      fs.file('bin/cache/artifacts/engine/linux-x64/libflutter_linux.so').createSync(recursive: true);
      fs.file('bin/cache/artifacts/engine/linux-x64/flutter_export.h').createSync();
      fs.file('bin/cache/artifacts/engine/linux-x64/flutter_messenger.h').createSync();
      fs.file('bin/cache/artifacts/engine/linux-x64/flutter_plugin_registrar.h').createSync();
      fs.file('bin/cache/artifacts/engine/linux-x64/flutter_glfw.h').createSync();
      fs.file('bin/cache/artifacts/engine/linux-x64/icudtl.dat').createSync();
      fs.file('bin/cache/artifacts/engine/linux-x64/cpp_client_wrapper/foo').createSync(recursive: true);
      fs.file('packages/flutter_tools/lib/src/build_system/targets/linux.dart').createSync(recursive: true);
      fs.directory('linux').createSync();
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
    });
  });

  test('Copies files to correct cache directory', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const UnpackLinux(), environment);

    expect(result.hasException, false);
    expect(fs.file('linux/flutter/libflutter_linux.so').existsSync(), true);
    expect(fs.file('linux/flutter/flutter_export.h').existsSync(), true);
    expect(fs.file('linux/flutter/flutter_messenger.h').existsSync(), true);
    expect(fs.file('linux/flutter/flutter_plugin_registrar.h').existsSync(), true);
    expect(fs.file('linux/flutter/flutter_glfw.h').existsSync(), true);
    expect(fs.file('linux/flutter/icudtl.dat').existsSync(), true);
    expect(fs.file('linux/flutter/cpp_client_wrapper/foo').existsSync(), true);
  }));

  test('Does not re-copy files unecessarily', () => testbed.run(() async {
    await buildSystem.build(const UnpackLinux(), environment);
    // Set a date in the far distant past to deal with the limited resolution
    // of the windows filesystem.
    final DateTime theDistantPast = DateTime(1991, 8, 23);
    fs.file('linux/flutter/libflutter_linux.so').setLastModifiedSync(theDistantPast);
    await buildSystem.build(const UnpackLinux(), environment);

    expect(fs.file('linux/flutter/libflutter_linux.so').statSync().modified, equals(theDistantPast));
  }));

  test('Detects changes in input cache files', () => testbed.run(() async {
    await buildSystem.build(const UnpackLinux(), environment);
    fs.file('bin/cache/artifacts/engine/linux-x64/libflutter_linux.so').writeAsStringSync('asd'); // modify cache.

    await buildSystem.build(const UnpackLinux(), environment);

    expect(fs.file('linux/flutter/libflutter_linux.so').readAsStringSync(), 'asd');
  }));
}

class MockPlatform extends Mock implements Platform {}
