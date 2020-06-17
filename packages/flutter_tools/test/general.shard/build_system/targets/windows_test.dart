// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';

final Platform kWindowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{},
);

const List<String> kRequiredFiles = <String>[
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_export.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_messenger.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.exp',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.lib',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.pdb',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_plugin_registrar.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\icudtl.dat',
  r'C:\bin\cache\artifacts\engine\windows-x64\cpp_client_wrapper\foo',
  r'C:\packages\flutter_tools\lib\src\build_system\targets\windows.dart',
];

void main() {
  testWithoutContext('UnpackWindows copies files to the correct cache directory', () async {
    final MockArtifacts artifacts = MockArtifacts();
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

    when(artifacts.getArtifactPath(
      Artifact.windowsDesktopPath,
      mode: anyNamed('mode'),
      platform: anyNamed('platform')
    )).thenReturn(r'C:\bin\cache\artifacts\engine\windows-x64\');
    when(artifacts.getArtifactPath(
      Artifact.windowsCppClientWrapper,
      mode: anyNamed('mode'),
      platform: anyNamed('platform')
    )).thenReturn(r'C:\bin\cache\artifacts\engine\windows-x64\cpp_client_wrapper\');
    when(artifacts.getArtifactPath(
      Artifact.icuData,
      mode: anyNamed('mode'),
      platform: anyNamed('platform')
    )).thenReturn(r'C:\bin\cache\artifacts\engine\windows-x64\icudtl.dat');
    for (final String path in kRequiredFiles) {
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
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\flutter_windows.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\icudtl.dat'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\ephemeral\cpp_client_wrapper\foo'), exists);


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
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_export.h',
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_messenger.h',
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll',
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.exp',
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.lib',
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll.pdb',
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_plugin_registrar.h',
      r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.h',
      r'C:\bin\cache\artifacts\engine\windows-x64\icudtl.dat',
      r'C:\bin\cache\artifacts\engine\windows-x64\cpp_client_wrapper\foo',
    ]));
    expect(outputPaths, unorderedEquals(<String>[
      r'C:\windows\flutter\ephemeral\flutter_export.h',
      r'C:\windows\flutter\ephemeral\flutter_messenger.h',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll.exp',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll.lib',
      r'C:\windows\flutter\ephemeral\flutter_windows.dll.pdb',
      r'C:\windows\flutter\ephemeral\flutter_plugin_registrar.h',
      r'C:\windows\flutter\ephemeral\flutter_windows.h',
      r'C:\windows\flutter\ephemeral\icudtl.dat',
      r'C:\windows\flutter\ephemeral\cpp_client_wrapper\foo',
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
      artifacts: MockArtifacts(),
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
      artifacts: MockArtifacts(),
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
      artifacts: MockArtifacts(),
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

class MockArtifacts extends Mock implements Artifacts {}
