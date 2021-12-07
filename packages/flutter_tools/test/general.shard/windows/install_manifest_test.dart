// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/windows/install_manifest.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Platform platform = FakePlatform(operatingSystem: 'windows');

void main() {
  FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
  });

  testUsingContext('Generates install manifest for a debug build', () async {
    final Logger logger = BufferLogger.test();
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final Directory buildDirectory = fileSystem.currentDirectory
      .childDirectory('build')
      .childDirectory('winuwp');

    await createManifest(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      project: flutterProject.windowsUwp,
      buildDirectory: buildDirectory,
      buildInfo: BuildInfo.debug,
    );

    final File manifest = flutterProject.windowsUwp.ephemeralDirectory.childFile('install_manifest');
    expect(manifest, exists);
    expect(manifest.readAsLinesSync(), unorderedEquals(<String>[
      'C:/build/flutter_assets/kernel_blob.bin',
      'C:/build/flutter_assets/AssetManifest.json',
      'C:/winuwp/flutter/ephemeral/flutter_windows_winuwp.dll',
      'C:/winuwp/flutter/ephemeral/flutter_windows_winuwp.dll.pdb',
      'C:/winuwp/flutter/ephemeral/icudtl.dat',
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Generates install manifest for a release build', () async {
    final Logger logger = BufferLogger.test();
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final Directory buildDirectory = fileSystem.currentDirectory
      .childDirectory('build')
      .childDirectory('winuwp');

    await createManifest(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      project: flutterProject.windowsUwp,
      buildDirectory: buildDirectory,
      buildInfo: BuildInfo.release,
    );

    final File manifest = flutterProject.windowsUwp.ephemeralDirectory.childFile('install_manifest');
    expect(manifest, exists);
    expect(manifest.readAsLinesSync(), unorderedEquals(<String>[
      'C:/build/winuwp/app.so',
      'C:/build/flutter_assets/AssetManifest.json',
      'C:/winuwp/flutter/ephemeral/flutter_windows_winuwp.dll',
      'C:/winuwp/flutter/ephemeral/flutter_windows_winuwp.dll.pdb',
      'C:/winuwp/flutter/ephemeral/icudtl.dat'
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Generates install manifest for a release build with assets', () async {
    final BufferLogger logger = BufferLogger.test();
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final Directory buildDirectory = fileSystem.currentDirectory
      .childDirectory('build')
      .childDirectory('winuwp');

    fileSystem.currentDirectory.childDirectory('.dart_tool').childFile('package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
{
  "configVersion": 2,
  "packages": []
}

''');
    fileSystem.currentDirectory.childFile('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: foo

flutter:
  assets:
    - assets/foo.png

''');
    fileSystem.currentDirectory
      .childDirectory('assets')
      .childFile('foo.png')
      .createSync(recursive: true);

    await createManifest(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      project: flutterProject.windowsUwp,
      buildDirectory: buildDirectory,
      buildInfo: BuildInfo.release,
    );

    final File manifest = flutterProject.windowsUwp.ephemeralDirectory.childFile('install_manifest');
    expect(manifest, exists);
    expect(manifest.readAsLinesSync(), unorderedEquals(<String>[
      'C:/build/winuwp/app.so',
      'C:/build/flutter_assets/assets/foo.png',
      'C:/build/flutter_assets/AssetManifest.json',
      'C:/build/flutter_assets/FontManifest.json',
      'C:/build/flutter_assets/NOTICES.Z',
      'C:/winuwp/flutter/ephemeral/flutter_windows_winuwp.dll',
      'C:/winuwp/flutter/ephemeral/flutter_windows_winuwp.dll.pdb',
      'C:/winuwp/flutter/ephemeral/icudtl.dat'
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}
