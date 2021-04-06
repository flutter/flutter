// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/windows.dart';
import 'package:flutter_tools/src/convert.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

final Platform kWindowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{},
);

void main() {
  testWithoutContext('UnpackWindows copies files to the correct windows/ cache directory', () async {
    final Artifacts artifacts = Artifacts.test();
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      defines: <String, String>{
        kBuildMode: 'debug',
      },
    );
    final DepfileService depfileService = DepfileService(
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
    );
    environment.buildDir.createSync(recursive: true);

    final String windowsDesktopPath = artifacts.getArtifactPath(Artifact.windowsDesktopPath, platform: TargetPlatform.windows_x64, mode: BuildMode.debug);
    final String windowsCppClientWrapper = artifacts.getArtifactPath(Artifact.windowsCppClientWrapper, platform: TargetPlatform.windows_x64, mode: BuildMode.debug);
    final String icuData = artifacts.getArtifactPath(Artifact.icuData, platform: TargetPlatform.windows_x64);
    final List<String> requiredFiles = <String>[
      '$windowsDesktopPath\\flutter_export.h',
      '$windowsDesktopPath\\flutter_messenger.h',
      '$windowsDesktopPath\\flutter_windows.dll',
      '$windowsDesktopPath\\flutter_windows.dll.exp',
      '$windowsDesktopPath\\flutter_windows.dll.lib',
      '$windowsDesktopPath\\flutter_windows.dll.pdb',
      '$windowsDesktopPath\\flutter_plugin_registrar.h',
      '$windowsDesktopPath\\flutter_texture_registrar.h',
      '$windowsDesktopPath\\flutter_windows.h',
      icuData,
      '$windowsCppClientWrapper\\foo',
      r'C:\packages\flutter_tools\lib\src\build_system\targets\windows.dart',
    ];

    for (final String path in requiredFiles) {
      fileSystem.file(path).createSync(recursive: true);
    }
    fileSystem.directory('windows').createSync();

    await const UnpackWindows().build(environment);

    // Output files are copied correctly.
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_export.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_messenger.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_windows.dll'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_windows.dll.exp'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_windows.dll.lib'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_windows.dll.pdb'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_export.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_messenger.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_plugin_registrar.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_texture_registrar.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_windows.h'), exists);
    expect(fileSystem.file('C:\\windows\\flutter\\ephemeral\\$icuData'), exists);
    expect(fileSystem.file('C:\\windows\\flutter\\ephemeral\\$windowsCppClientWrapper\\foo'), exists);

    final File outputDepfile = environment.buildDir
      .childFile('windows_engine_sources.d');

    // Depfile is created correctly.
    expect(outputDepfile, exists);

    final List<String> inputPaths = depfileService.parse(outputDepfile)
      .inputs.map((File file) => file.path).toList();
    final List<String> outputPaths = depfileService.parse(outputDepfile)
      .outputs.map((File file) => file.path).toList();

    // Depfile has expected sources.
    expect(inputPaths, unorderedEquals(<String>[
      '$windowsDesktopPath\\flutter_export.h',
      '$windowsDesktopPath\\flutter_messenger.h',
      '$windowsDesktopPath\\flutter_windows.dll',
      '$windowsDesktopPath\\flutter_windows.dll.exp',
      '$windowsDesktopPath\\flutter_windows.dll.lib',
      '$windowsDesktopPath\\flutter_windows.dll.pdb',
      '$windowsDesktopPath\\flutter_plugin_registrar.h',
      '$windowsDesktopPath\\flutter_texture_registrar.h',
      '$windowsDesktopPath\\flutter_windows.h',
      icuData,
      '$windowsCppClientWrapper\\foo',
    ]));
    expect(outputPaths, unorderedEquals(<String>[
      r'C:\windows\flutter\ephemeral\flutter_export.h',
      r'C:\windows\flutter\ephemeral\flutter_messenger.h',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll.exp',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll.lib',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll.pdb',
      r'C:\windows\flutter\ephemeral\flutter_plugin_registrar.h',
      r'C:\windows\flutter\ephemeral\flutter_texture_registrar.h',
      r'C:\windows\flutter\ephemeral\flutter_windows.h',
      'C:\\windows\\flutter\\ephemeral\\$icuData',
      'C:\\windows\\flutter\\ephemeral\\$windowsCppClientWrapper\\foo',
    ]));
  });

  testWithoutContext('UnpackWindowsUwp copies files to the correct winuwp/ cache directory', () async {
    final Artifacts artifacts = Artifacts.test();
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      defines: <String, String>{
        kBuildMode: 'debug',
      },
    );
    final DepfileService depfileService = DepfileService(
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
    );
    environment.buildDir.createSync(recursive: true);

    final String windowsDesktopPath = artifacts.getArtifactPath(Artifact.windowsDesktopPath, platform: TargetPlatform.windows_x64, mode: BuildMode.debug);
    final String windowsCppClientWrapper = artifacts.getArtifactPath(Artifact.windowsCppClientWrapper, platform: TargetPlatform.windows_x64, mode: BuildMode.debug);
    final String icuData = artifacts.getArtifactPath(Artifact.icuData, platform: TargetPlatform.windows_x64);
    final List<String> requiredFiles = <String>[
      '$windowsDesktopPath\\flutter_export.h',
      '$windowsDesktopPath\\flutter_messenger.h',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll.exp',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll.lib',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll.pdb',
      '$windowsDesktopPath\\flutter_plugin_registrar.h',
      '$windowsDesktopPath\\flutter_texture_registrar.h',
      '$windowsDesktopPath\\flutter_windows.h',
      icuData,
      '$windowsCppClientWrapper\\foo',
      r'C:\packages\flutter_tools\lib\src\build_system\targets\windows.dart',
    ];

    for (final String path in requiredFiles) {
      fileSystem.file(path).createSync(recursive: true);
    }
    fileSystem.directory('windows').createSync();

    await const UnpackWindowsUwp().build(environment);

    // Output files are copied correctly.
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_export.h'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_messenger.h'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll.exp'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll.lib'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll.pdb'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_export.h'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_messenger.h'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_plugin_registrar.h'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_texture_registrar.h'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\ephemeral\flutter_windows.h'), exists);
    expect(fileSystem.file(r'C:\winuwp\flutter\flutter_windows.h'), exists);
    expect(fileSystem.file('C:\\winuwp\\flutter\\ephemeral\\$icuData'), exists);
    expect(fileSystem.file('C:\\winuwp\\flutter\\ephemeral\\$windowsCppClientWrapper\\foo'), exists);

    final File outputDepfile = environment.buildDir
      .childFile('windows_uwp_engine_sources.d');

    // Depfile is created correctly.
    expect(outputDepfile, exists);

    final List<String> inputPaths = depfileService.parse(outputDepfile)
      .inputs.map((File file) => file.path).toList();
    final List<String> outputPaths = depfileService.parse(outputDepfile)
      .outputs.map((File file) => file.path).toList();

    // Depfile has expected sources.
    expect(inputPaths, unorderedEquals(<String>[
      '$windowsDesktopPath\\flutter_export.h',
      '$windowsDesktopPath\\flutter_messenger.h',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll.exp',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll.lib',
      '$windowsDesktopPath\\flutter_windows_winuwp.dll.pdb',
      '$windowsDesktopPath\\flutter_plugin_registrar.h',
      '$windowsDesktopPath\\flutter_texture_registrar.h',
      '$windowsDesktopPath\\flutter_windows.h',
      icuData,
      '$windowsCppClientWrapper\\foo',
    ]));
    expect(outputPaths, unorderedEquals(<String>[
      r'C:\winuwp\flutter\ephemeral\flutter_export.h',
      r'C:\winuwp\flutter\ephemeral\flutter_messenger.h',
      r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll',
      r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll.exp',
      r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll.lib',
      r'C:\winuwp\flutter\ephemeral\flutter_windows_winuwp.dll.pdb',
      r'C:\winuwp\flutter\ephemeral\flutter_plugin_registrar.h',
      r'C:\winuwp\flutter\ephemeral\flutter_texture_registrar.h',
      r'C:\winuwp\flutter\ephemeral\flutter_windows.h',
      r'C:\winuwp\flutter\flutter_windows.h',
      'C:\\winuwp\\flutter\\ephemeral\\$icuData',
      'C:\\winuwp\\flutter\\ephemeral\\$windowsCppClientWrapper\\foo',
    ]));
  });

  // AssetBundleFactory still uses context injection
  FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
  });

  testUsingContext('DebugBundleWindowsAssets creates correct bundle structure', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      defines: <String, String>{
        kBuildMode: 'debug',
      },
      inputs: <String, String>{
        kBundleSkSLPath: 'bundle.sksl',
      },
      engineVersion: '2',
    );

    environment.buildDir.childFile('app.dill').createSync(recursive: true);
    // sksl bundle
    fileSystem.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, Object>{
        'engineRevision': '2',
        'platform': 'ios',
        'data': <String, Object>{
          'A': 'B',
        }
      }
    ));

    await const DebugBundleWindowsAssets().build(environment);

    // Depfile is created and dill is copied.
    expect(environment.buildDir.childFile('flutter_assets.d'), exists);
    expect(fileSystem.file(r'C:\flutter_assets\kernel_blob.bin'), exists);
    expect(fileSystem.file(r'C:\flutter_assets\AssetManifest.json'), exists);
    expect(fileSystem.file(r'C:\flutter_assets\io.flutter.shaders.json'), exists);
    expect(fileSystem.file(r'C:\flutter_assets\io.flutter.shaders.json').readAsStringSync(), '{"data":{"A":"B"}}');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ProfileBundleWindowsAssets creates correct bundle structure', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      defines: <String, String>{
        kBuildMode: 'profile',
      }
    );

    environment.buildDir.childFile('app.so').createSync(recursive: true);

    await const WindowsAotBundle(AotElfProfile(TargetPlatform.windows_x64)).build(environment);
    await const ProfileBundleWindowsAssets().build(environment);

    // Depfile is created and so is copied.
    expect(environment.buildDir.childFile('flutter_assets.d'), exists);
    expect(fileSystem.file(r'C:\windows\app.so'), exists);
    expect(fileSystem.file(r'C:\flutter_assets\kernel_blob.bin').existsSync(), false);
    expect(fileSystem.file(r'C:\flutter_assets\AssetManifest.json'), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ReleaseBundleWindowsAssets creates correct bundle structure', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      defines: <String, String>{
        kBuildMode: 'release',
      }
    );

    environment.buildDir.childFile('app.so').createSync(recursive: true);

    await const WindowsAotBundle(AotElfRelease(TargetPlatform.windows_x64)).build(environment);
    await const ReleaseBundleWindowsAssets().build(environment);

    // Depfile is created and so is copied.
    expect(environment.buildDir.childFile('flutter_assets.d'), exists);
    expect(fileSystem.file(r'C:\windows\app.so'), exists);
    expect(fileSystem.file(r'C:\flutter_assets\kernel_blob.bin').existsSync(), false);
    expect(fileSystem.file(r'C:\flutter_assets\AssetManifest.json'), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}
