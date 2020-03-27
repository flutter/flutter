// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/windows.dart';

import '../../../src/common.dart';
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
  r'C:\bin\cache\artifacts\engine\windows-x64\lutter_export.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_messenger.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_plugin_registrar.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\flutter_windows.h',
  r'C:\bin\cache\artifacts\engine\windows-x64\icudtl.dat',
  r'C:\bin\cache\artifacts\engine\windows-x64\cpp_client_wrapper\foo',
  r'C:\packages\flutter_tools\lib\src\build_system\targets\windows.dart',
];

void main() {
  Environment environment;
  FileSystem fileSystem;

  setUp(() {
    final MockArtifacts artifacts = MockArtifacts();
    when(artifacts.getArtifactPath(Artifact.windowsDesktopPath))
      .thenReturn(r'C:\bin\cache\artifacts\engine\windows-x64\');
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    for (final String path in kRequiredFiles) {
      fileSystem.file(path).createSync(recursive: true);
    }
    fileSystem.directory('windows').createSync();
  });

  testWithoutContext('UnpackWindows copies files to the correct cache directory', () async {
    await const UnpackWindows().build(environment);

    expect(fileSystem.file(r'C:\windows\flutter\flutter_export.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_messenger.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_windows.dll'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_windows.dll.exp'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_windows.dll.lib'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_windows.dll.pdb'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_export.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_messenger.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_plugin_registrar.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\flutter_windows.h'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\icudtl.dat'), exists);
    expect(fileSystem.file(r'C:\windows\flutter\cpp_client_wrapper\foo'), exists);
  });
}

class MockArtifacts extends Mock implements Artifacts {}
