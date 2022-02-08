// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

// Tests for the temporary flutter assemble/bundle shim.
void main() {
  testUsingContext('Copies assets to expected directory after building', () async {
    await buildWithAssemble(
      buildMode: BuildMode.debug,
      flutterProject: FlutterProject.fromDirectoryTest(globals.fs.currentDirectory),
      mainPath: globals.fs.path.join('lib', 'main.dart'),
      outputDir: 'example',
      targetPlatform: TargetPlatform.ios,
      depfilePath: 'example.d',
      treeShakeIcons: false,
    );
    expect(globals.fs.file(globals.fs.path.join('example', 'kernel_blob.bin')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join('example', 'LICENSE')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join('example.d')).existsSync(), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      environment.outputDir.childFile('kernel_blob.bin').createSync(recursive: true);
      environment.outputDir.childFile('isolate_snapshot_data').createSync();
      environment.outputDir.childFile('vm_snapshot_data').createSync();
      environment.outputDir.childFile('LICENSE').createSync(recursive: true);
    }),
  });

  testUsingContext('Handles build system failure', () {
    expect(() => buildWithAssemble(
      buildMode: BuildMode.debug,
      flutterProject: FlutterProject.fromDirectoryTest(globals.fs.currentDirectory),
      mainPath: 'lib/main.dart',
      outputDir: 'example',
      targetPlatform: TargetPlatform.linux_x64,
      depfilePath: 'example.d',
      treeShakeIcons: false,
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: false)),
  });
}
