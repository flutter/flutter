// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:flutter_tools/src/convert.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  Environment environment;
  FileSystem fileSystem;
  Artifacts artifacts;
  FakeProcessManager processManager;

  setUp(() {
    processManager = FakeProcessManager.any();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'darwin-x64',
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      engineVersion: '2'
    );
  });

  testUsingContext('Copies files to correct cache directory', () async {
    final Directory outputDir = fileSystem.directory('output');
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          'rsync',
          '-av',
          '--delete',
          '--filter',
          '- .DS_Store/',
          'Artifact.flutterMacOSFramework.debug',
          outputDir.path,
        ],
      ),
    ]);
    environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'darwin-x64',
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      engineVersion: '2',
      outputDir: outputDir,
    );

    await const DebugUnpackMacOS().build(environment);

    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debug macOS application fails if App.framework missing', () async {
    fileSystem.directory(
      artifacts.getArtifactPath(
        Artifact.flutterMacOSFramework,
        mode: BuildMode.debug,
      ))
      .createSync();
    final String inputKernel = fileSystem.path.join(environment.buildDir.path, 'app.dill');
    fileSystem.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    expect(() async => await const DebugMacOSBundleFlutterAssets().build(environment),
        throwsException);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debug macOS application creates correctly structured framework', () async {
    fileSystem.directory(
      artifacts.getArtifactPath(
        Artifact.flutterMacOSFramework,
        mode: BuildMode.debug,
      ))
      .createSync();
    environment.inputs[kBundleSkSLPath] = 'bundle.sksl';
    fileSystem.file(
      artifacts.getArtifactPath(
        Artifact.vmSnapshotData,
        platform: TargetPlatform.darwin_x64,
        mode: BuildMode.debug,
      )).createSync(recursive: true);
    fileSystem.file(
      artifacts.getArtifactPath(
        Artifact.isolateSnapshotData,
        platform: TargetPlatform.darwin_x64,
        mode: BuildMode.debug,
      )).createSync(recursive: true);
    fileSystem.file('${environment.buildDir.path}/App.framework/App')
      .createSync(recursive: true);
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

    final String inputKernel = '${environment.buildDir.path}/app.dill';
    fileSystem.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    await const DebugMacOSBundleFlutterAssets().build(environment);

    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/kernel_blob.bin').readAsStringSync(),
      'testing',
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/Info.plist').readAsStringSync(),
      contains('io.flutter.flutter.app'),
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/vm_snapshot_data'),
      exists,
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/isolate_snapshot_data'),
      exists,
    );

    final File skslFile = fileSystem.file('App.framework/Versions/A/Resources/flutter_assets/io.flutter.shaders.json');

    expect(skslFile, exists);
    expect(skslFile.readAsStringSync(), '{"data":{"A":"B"}}');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('release/profile macOS application has no blob or precompiled runtime', () async {
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/vm_isolate_snapshot.bin')
      .createSync(recursive: true);
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/isolate_snapshot.bin')
      .createSync(recursive: true);
    fileSystem.file('${environment.buildDir.path}/App.framework/App')
      .createSync(recursive: true);

    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');

    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/kernel_blob.bin'),
      isNot(exists),
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/vm_snapshot_data'),
      isNot(exists),
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/isolate_snapshot_data'),
      isNot(exists),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('release/profile macOS application updates when App.framework updates', () async {
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/vm_isolate_snapshot.bin')
      .createSync(recursive: true);
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/isolate_snapshot.bin')
      .createSync(recursive: true);
    final File inputFramework = fileSystem.file(fileSystem.path.join(environment.buildDir.path, 'App.framework', 'App'))
      ..createSync(recursive: true)
      ..writeAsStringSync('ABC');

    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');
    final File outputFramework = fileSystem.file(fileSystem.path.join(environment.outputDir.path, 'App.framework', 'App'));

    expect(outputFramework.readAsStringSync(), 'ABC');

    inputFramework.writeAsStringSync('DEF');
    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');

    expect(outputFramework.readAsStringSync(), 'DEF');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });
}
