// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('unpack_macos', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;
    MockPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockPlatform();
      when(mockPlatform.isWindows).thenReturn(false);
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
          targetPlatform: TargetPlatform.darwin_x64,
          buildMode: BuildMode.debug,
        );
        buildSystem = const BuildSystem(<Target>[
          unpackMacos,
        ]);
        fs.directory('cache/darwin-x64/FlutterMacOS.framework').createSync(recursive: true);
        fs.file('cache/darwin-x64/FlutterMacOS.framework/foo').createSync();
        when(processManager.runSync(any)).thenAnswer((Invocation invocation) {
          final List<String> arguments = invocation.positionalArguments.first;
          fs.directory(arguments.last).createSync(recursive: true);
          return FakeProcessResult()..exitCode = 0;
        });
      }, overrides: <Type, Generator>{
        ProcessManager: () => MockProcessManager(),
        MockPlatform: () => mockPlatform,
      });
    });

    test('Copies files to correct cache directory', () => testbed.run(() async {
      await buildSystem.build('unpack_macos', environment);

      expect(fs.directory('macos/flutter/FlutterMacOS.framework').existsSync(), true);
    }));
  });
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
