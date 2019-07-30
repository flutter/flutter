// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

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
    when(mockPlatform.isMacOS).thenReturn(true);
    when(mockPlatform.isLinux).thenReturn(false);
    testbed = Testbed(setup: () {
      environment = Environment(
        projectDir: fs.currentDirectory,
      );
      final List<File> inputs = <File>[
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/FlutterMacOS'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEOpenGLContextHandling.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEReshapeListener.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEView.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEViewController.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterBinaryMessenger.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterChannels.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterCodecs.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterMacOS.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterPluginMacOS.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterPluginRegisrarMacOS.h'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Modules/module.modulemap'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Resources/icudtl.dat'),
        fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Resources/info.plist'),
        fs.file('packages/flutter_tools/lib/src/build_system/targets/macos.dart'),
      ];
      for (File input in inputs) {
        input.createSync(recursive: true);
      }
      when(processManager.run(any)).thenAnswer((Invocation invocation) async {
        final List<String> arguments = invocation.positionalArguments.first;
        final Directory source = fs.directory(arguments[arguments.length - 2]);
        final Directory target = fs.directory(arguments.last)
          ..createSync(recursive: true);
        for (FileSystemEntity entity in source.listSync(recursive: true)) {
          if (entity is File) {
            final String relative = fs.path.relative(entity.path, from: source.path);
            final String destination = fs.path.join(target.path, relative);
            if (!fs.file(destination).parent.existsSync()) {
              fs.file(destination).parent.createSync();
            }
            entity.copySync(destination);
          }
        }
        return FakeProcessResult()..exitCode = 0;
      });
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Platform: () => mockPlatform,
    });
  });

  test('Copies files to correct cache directory', () => testbed.run(() async {
    await buildSystem.build(const UnpackMacOS(), environment);

    expect(fs.directory('macos/Flutter/FlutterMacOS.framework').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/FlutterMacOS').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FLEOpenGLContextHandling.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FLEReshapeListener.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FLEView.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FLEViewController.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FlutterBinaryMessenger.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FlutterChannels.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FlutterCodecs.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FlutterMacOS.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FlutterPluginMacOS.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Headers/FlutterPluginRegisrarMacOS.h').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Modules/module.modulemap').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Resources/icudtl.dat').existsSync(), true);
    expect(fs.file('macos/Flutter/FlutterMacOS.framework/Resources/info.plist').existsSync(), true);
  }));
}

class MockPlatform extends Mock implements Platform {}

class MockProcessManager extends Mock implements ProcessManager {}
class FakeProcessResult implements ProcessResult {
  @override
  int exitCode;

  @override
  int pid = 0;

  @override
  String stderr = '';

  @override
  String stdout = '';
}
