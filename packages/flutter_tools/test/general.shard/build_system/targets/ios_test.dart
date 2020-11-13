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
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/convert.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';

final Platform macPlatform = FakePlatform(operatingSystem: 'macos', environment: <String, String>{});

const List<String> _kSharedConfig = <String>[
  '-dynamiclib',
  '-fembed-bitcode-marker',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@executable_path/Frameworks',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@loader_path/Frameworks',
  '-install_name',
  '@rpath/App.framework/App',
  '-isysroot',
];

void main() {
  Environment environment;
  FileSystem fileSystem;
  FakeProcessManager processManager;
  Artifacts artifacts;
  Logger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kTargetPlatform: 'ios',
      },
      inputs: <String, String>{},
      processManager: processManager,
      artifacts: artifacts,
      logger: logger,
      fileSystem: fileSystem,
      engineVersion: '2',
    );
  });

  testWithoutContext('iOS AOT targets has analyicsName', () {
    expect(const AotAssemblyRelease().analyticsName, 'ios_aot');
    expect(const AotAssemblyProfile().analyticsName, 'ios_aot');
  });

  testUsingContext('DebugUniveralFramework creates expected binary with arm64 only arch', () async {
    environment.defines[kIosArchs] = 'arm64';
    processManager.addCommands(<FakeCommand>[
      // Create iphone stub.
      const FakeCommand(
        command: <String>[
          'sysctl',
          'hw.optional.arm64',
        ],
        exitCode: 1,
      ),
      const FakeCommand(command: <String>['xcrun', '--sdk', 'iphoneos', '--show-sdk-path']),
      FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-x',
        'c',
         // iphone only gets 64 bit arch based on kIosArchs
        '-arch',
        'arm64',
        fileSystem.path.absolute(fileSystem.path.join('.tmp_rand0', 'flutter_tools_stub_source.rand0', 'debug_app.cc')),
        ..._kSharedConfig,
        '',
        '-o',
        environment.buildDir.childFile('iphone_framework').path
      ]),
      // Create simulator stub.
      const FakeCommand(command: <String>['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path']),
      FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-x',
        'c',
        // Simulator only as x86_64 arch
        '-arch',
        'x86_64',
        fileSystem.path.absolute(fileSystem.path.join('.tmp_rand0', 'flutter_tools_stub_source.rand0', 'debug_app.cc')),
        ..._kSharedConfig,
        '',
        '-o',
        environment.buildDir.childFile('simulator_framework').path
      ]),
      // Lipo stubs together.
      FakeCommand(command: <String>[
        'xcrun',
        'lipo',
        '-create',
        environment.buildDir.childFile('iphone_framework').path,
        environment.buildDir.childFile('simulator_framework').path,
        '-output',
        environment.buildDir.childDirectory('App.framework').childFile('App').path,
      ]),
    ]);

    await const DebugUniveralFramework().build(environment);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => macPlatform,
  });

  testUsingContext('DebugIosApplicationBundle', () async {
    environment.inputs[kBundleSkSLPath] = 'bundle.sksl';
    environment.defines[kBuildMode] = 'debug';
    // Precompiled dart data

    fileSystem.file(artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
      .createSync();
    fileSystem.file(artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
      .createSync();
    // Project info
    fileSystem.file('pubspec.yaml').writeAsStringSync('name: hello');
    fileSystem.file('.packages').writeAsStringSync('\n');
    // Plist file
    fileSystem.file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
      .createSync(recursive: true);
    // App kernel
    environment.buildDir.childFile('app.dill').createSync(recursive: true);
    // Stub framework
    environment.buildDir
      .childDirectory('App.framework')
      .childFile('App')
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

    await const DebugIosApplicationBundle().build(environment);

    final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
    expect(frameworkDirectory.childFile('App'), exists);
    expect(frameworkDirectory.childFile('Info.plist'), exists);

    final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
    expect(assetDirectory.childFile('kernel_blob.bin'), exists);
    expect(assetDirectory.childFile('AssetManifest.json'), exists);
    expect(assetDirectory.childFile('vm_snapshot_data'), exists);
    expect(assetDirectory.childFile('isolate_snapshot_data'), exists);
    expect(assetDirectory.childFile('io.flutter.shaders.json'), exists);
    expect(assetDirectory.childFile('io.flutter.shaders.json').readAsStringSync(), '{"data":{"A":"B"}}');
  });

  testUsingContext('ReleaseIosApplicationBundle', () async {
    environment.defines[kBuildMode] = 'release';

    // Project info
    fileSystem.file('pubspec.yaml').writeAsStringSync('name: hello');
    fileSystem.file('.packages').writeAsStringSync('\n');
    // Plist file
    fileSystem.file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
      .createSync(recursive: true);

    // Real framework
    environment.buildDir
      .childDirectory('App.framework')
      .childFile('App')
      .createSync(recursive: true);

    await const ReleaseIosApplicationBundle().build(environment);

    final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
    expect(frameworkDirectory.childFile('App'), exists);
    expect(frameworkDirectory.childFile('Info.plist'), exists);

    final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
    expect(assetDirectory.childFile('kernel_blob.bin'), isNot(exists));
    expect(assetDirectory.childFile('AssetManifest.json'), exists);
    expect(assetDirectory.childFile('vm_snapshot_data'), isNot(exists));
    expect(assetDirectory.childFile('isolate_snapshot_data'), isNot(exists));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => macPlatform,
  });

  testUsingContext('AotAssemblyRelease throws exception if asked to build for x86 target', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kTargetPlatform: 'ios',
      },
      processManager: processManager,
      artifacts: artifacts,
      logger: logger,
      fileSystem: fileSystem,
    );
    environment.defines[kBuildMode] = 'release';
    environment.defines[kIosArchs] = 'x86_64';

    expect(const AotAssemblyRelease().build(environment), throwsA(isA<Exception>()
      .having(
        (Exception exception) => exception.toString(),
        'description',
        contains('release/profile builds are only supported for physical devices.'),
      )
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => macPlatform,
  });
}
