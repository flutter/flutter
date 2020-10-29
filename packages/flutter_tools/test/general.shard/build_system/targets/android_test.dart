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
import 'package:flutter_tools/src/build_system/targets/android.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/convert.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';

final Platform platform = FakePlatform(operatingSystem: 'linux', environment: const <String, String>{});
void main() {
  FakeProcessManager processManager;
  FileSystem fileSystem;
  Artifacts artifacts;
  Logger logger;

  setUp(() {
    logger = BufferLogger.test();
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    artifacts = Artifacts.test();
  });

  testWithoutContext('Android AOT targets has analyicsName', () {
    expect(androidArmProfile.analyticsName, 'android_aot');
  });

  testUsingContext('debug bundle contains expected resources', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'debug',
      },
      processManager: processManager,
      artifacts: artifacts,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.dill')
      .writeAsStringSync('abcd');
    fileSystem
      .file(artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
      .createSync(recursive: true);
    fileSystem
      .file(artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
      .createSync(recursive: true);

    await const DebugAndroidApplication().build(environment);

    expect(fileSystem.file(fileSystem.path.join('out', 'flutter_assets', 'isolate_snapshot_data')).existsSync(), true);
    expect(fileSystem.file(fileSystem.path.join('out', 'flutter_assets', 'vm_snapshot_data')).existsSync(), true);
    expect(fileSystem.file(fileSystem.path.join('out', 'flutter_assets', 'kernel_blob.bin')).existsSync(), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debug bundle contains expected resources with bundle SkSL', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'debug',
      },
      inputs: <String, String>{
        kBundleSkSLPath: 'bundle.sksl'
      },
      processManager: processManager,
      artifacts: artifacts,
      fileSystem: fileSystem,
      logger: logger,
      engineVersion: '2',
    );
    environment.buildDir.createSync(recursive: true);
    fileSystem.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, Object>{
        'engineRevision': '2',
        'platform': 'android',
        'data': <String, Object>{
          'A': 'B',
        }
      }
    ));

    // create pre-requisites.
    environment.buildDir.childFile('app.dill')
      .writeAsStringSync('abcd');
    fileSystem
      .file(artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
      .createSync(recursive: true);
    fileSystem
      .file(artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
      .createSync(recursive: true);

    await const DebugAndroidApplication().build(environment);

    expect(fileSystem.file(fileSystem.path.join('out', 'flutter_assets', 'isolate_snapshot_data')), exists);
    expect(fileSystem.file(fileSystem.path.join('out', 'flutter_assets', 'vm_snapshot_data')), exists);
    expect(fileSystem.file(fileSystem.path.join('out', 'flutter_assets', 'kernel_blob.bin')), exists);
    expect(fileSystem.file(fileSystem.path.join('out', 'flutter_assets', 'io.flutter.shaders.json')), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('profile bundle contains expected resources', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'profile',
      },
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.so')
      .writeAsStringSync('abcd');

    await const ProfileAndroidApplication().build(environment);

    expect(fileSystem.file(fileSystem.path.join('out', 'app.so')).existsSync(), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testWithoutContext('release bundle contains expected resources', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
      },
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.so')
      .writeAsStringSync('abcd');

    await const ReleaseAndroidApplication().build(environment);

    expect(fileSystem.file(fileSystem.path.join('out', 'app.so')).existsSync(), true);
  });

  testUsingContext('AndroidAot can build provided target platform', () async {
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
      },
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    processManager.addCommand(FakeCommand(command: <String>[
      artifacts.getArtifactPath(
        Artifact.genSnapshot,
        platform: TargetPlatform.android_arm64,
        mode: BuildMode.release,
      ),
      '--deterministic',
      '--snapshot_kind=app-aot-elf',
      '--elf=${environment.buildDir.childDirectory('arm64-v8a').childFile('app.so').path}',
      '--strip',
      '--no-causal-async-stacks',
      '--lazy-async-stacks',
      environment.buildDir.childFile('app.dill').path,
      ],
    ));
    environment.buildDir.createSync(recursive: true);
    environment.buildDir.childFile('app.dill').createSync();
    environment.projectDir.childFile('.packages').writeAsStringSync('\n');
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);

    await androidAot.build(environment);

    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('AndroidAot provide code size information.', () async {
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
        kCodeSizeDirectory: 'code_size_1',
      },
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    processManager.addCommand(FakeCommand(command: <String>[
      artifacts.getArtifactPath(
        Artifact.genSnapshot,
        platform: TargetPlatform.android_arm64,
        mode: BuildMode.release,
      ),
      '--deterministic',
      '--write-v8-snapshot-profile-to=code_size_1/snapshot.arm64-v8a.json',
      '--trace-precompiler-to=code_size_1/trace.arm64-v8a.json',
      '--snapshot_kind=app-aot-elf',
      '--elf=${environment.buildDir.childDirectory('arm64-v8a').childFile('app.so').path}',
      '--strip',
      '--no-causal-async-stacks',
      '--lazy-async-stacks',
      environment.buildDir.childFile('app.dill').path,
      ],
    ));
    environment.buildDir.createSync(recursive: true);
    environment.buildDir.childFile('app.dill').createSync();
    environment.projectDir.childFile('.packages').writeAsStringSync('\n');
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);

    await androidAot.build(environment);

    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('kExtraGenSnapshotOptions passes values to gen_snapshot', () async {
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
        kExtraGenSnapshotOptions: 'foo,bar,baz=2',
        kTargetPlatform: 'android-arm',
      },
      processManager: processManager,
      artifacts: artifacts,
      fileSystem: fileSystem,
      logger: logger,
    );
    processManager.addCommand(
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(
          Artifact.genSnapshot,
          platform: TargetPlatform.android_arm64,
          mode: BuildMode.release,
        ),
        '--deterministic',
        'foo',
        'bar',
        'baz=2',
        '--snapshot_kind=app-aot-elf',
        '--elf=${environment.buildDir.childDirectory('arm64-v8a').childFile('app.so').path}',
        '--strip',
        '--no-causal-async-stacks',
        '--lazy-async-stacks',
        environment.buildDir.childFile('app.dill').path
      ],
    ));
    environment.buildDir.createSync(recursive: true);
    environment.buildDir.childFile('app.dill').createSync();
    environment.projectDir.childFile('.packages').writeAsStringSync('\n');

    await const AndroidAot(TargetPlatform.android_arm64, BuildMode.release)
      .build(environment);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testWithoutContext('android aot bundle copies so from abi directory', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
      },
      processManager: processManager,
      artifacts: artifacts,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    // Create required files.
    environment.buildDir
      .childDirectory('arm64-v8a')
      .childFile('app.so')
      .createSync(recursive: true);

    await androidAotBundle.build(environment);

    expect(environment.outputDir
      .childDirectory('arm64-v8a')
      .childFile('app.so').existsSync(), true);
  });
}
