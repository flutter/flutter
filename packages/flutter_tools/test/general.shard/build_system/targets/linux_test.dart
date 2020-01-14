// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/linux.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
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
    when(mockPlatform.environment).thenReturn(Map<String, String>.unmodifiable(<String, String>{}));
    testbed = Testbed(setup: () {
      Cache.flutterRoot = '';
      environment = Environment.test(
        globals.fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: 'debug',
        }
      );
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/unrelated-stuff').createSync(recursive: true);
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/libflutter_linux_glfw.so').createSync(recursive: true);
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/flutter_export.h').createSync();
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/flutter_messenger.h').createSync();
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/flutter_plugin_registrar.h').createSync();
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/flutter_glfw.h').createSync();
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/icudtl.dat').createSync();
      globals.fs.file('bin/cache/artifacts/engine/linux-x64/cpp_client_wrapper_glfw/foo').createSync(recursive: true);
      globals.fs.file('packages/flutter_tools/lib/src/build_system/targets/linux.dart').createSync(recursive: true);
      globals.fs.directory('linux').createSync();
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
    });
  });

  test('Copies files to correct cache directory, excluding unrelated code', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const UnpackLinuxDebug(), environment);

    expect(result.hasException, false);
    expect(globals.fs.file('linux/flutter/ephemeral/libflutter_linux_glfw.so').existsSync(), true);
    expect(globals.fs.file('linux/flutter/ephemeral/flutter_export.h').existsSync(), true);
    expect(globals.fs.file('linux/flutter/ephemeral/flutter_messenger.h').existsSync(), true);
    expect(globals.fs.file('linux/flutter/ephemeral/flutter_plugin_registrar.h').existsSync(), true);
    expect(globals.fs.file('linux/flutter/ephemeral/flutter_glfw.h').existsSync(), true);
    expect(globals.fs.file('linux/flutter/ephemeral/icudtl.dat').existsSync(), true);
    expect(globals.fs.file('linux/flutter/ephemeral/cpp_client_wrapper_glfw/foo').existsSync(), true);
    expect(globals.fs.file('linux/flutter/ephemeral/unrelated-stuff').existsSync(), false);
  }));

  test('Does not re-copy files unecessarily', () => testbed.run(() async {
    await buildSystem.build(const UnpackLinuxDebug(), environment);
    // Set a date in the far distant past to deal with the limited resolution
    // of the windows filesystem.
    final DateTime theDistantPast = DateTime(1991, 8, 23);
    globals.fs.file('linux/flutter/ephemeral/libflutter_linux_glfw.so').setLastModifiedSync(theDistantPast);
    await buildSystem.build(const UnpackLinuxDebug(), environment);

    expect(globals.fs.file('linux/flutter/ephemeral/libflutter_linux_glfw.so').statSync().modified, equals(theDistantPast));
  }));

  test('Detects changes in input cache files', () => testbed.run(() async {
    await buildSystem.build(const UnpackLinuxDebug(), environment);
    globals.fs.file('bin/cache/artifacts/engine/linux-x64/libflutter_linux_glfw.so').writeAsStringSync('asd'); // modify cache.

    await buildSystem.build(const UnpackLinuxDebug(), environment);

    expect(globals.fs.file('linux/flutter/ephemeral/libflutter_linux_glfw.so').readAsStringSync(), 'asd');
  }));

  test('Copies artifacts to out directory', () => testbed.run(() async {
    environment.buildDir.createSync(recursive: true);

    // Create input files.
    environment.buildDir.childFile('app.dill').createSync();

    await const DebugBundleLinuxAssets().build(environment);
    final Directory output = environment.outputDir
      .childDirectory('flutter_assets');

    expect(output.childFile('kernel_blob.bin').existsSync(), true);
    expect(output.childFile('FontManifest.json').existsSync(), false);
    expect(output.childFile('AssetManifest.json').existsSync(), true);
  }));
}

class MockPlatform extends Mock implements Platform {}
