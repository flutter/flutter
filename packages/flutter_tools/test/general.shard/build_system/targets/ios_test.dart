// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/testbed.dart';

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
  Testbed testbed;
  Environment environment;
  ProcessManager processManager;

  setUp(() {
    testbed = Testbed(setup: () {
      environment = Environment.test(globals.fs.currentDirectory, defines: <String, String>{
        kTargetPlatform: 'ios',
      });
    });
  });

  test('DebugUniveralFramework creates expected binary', () => testbed.run(() async {
    processManager = FakeProcessManager.list(<FakeCommand>[
      // Create iphone stub.
      const FakeCommand(command: <String>['xcrun', '--sdk', 'iphoneos', '--show-sdk-path']),
      FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-x',
        'c',
         // iphone gets both arm arches
        '-arch',
        'armv7',
        '-arch',
        'arm64',
        globals.fs.path.absolute(globals.fs.path.join('.tmp_rand0', 'flutter_tools_stub_source.rand0', 'debug_app.cc')),
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
        globals.fs.path.absolute(globals.fs.path.join('.tmp_rand0', 'flutter_tools_stub_source.rand0', 'debug_app.cc')),
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
        environment.buildDir.childFile('App').path,
      ]),
    ]);

    await const DebugUniveralFramework().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));

  test('DebugIosApplicationBundle', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'debug';
    // Precompiled dart data
    when(globals.artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
      .thenReturn('vm_snapshot_data');
    when(globals.artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
      .thenReturn('isolate_snapshot_data');
    globals.fs.file('vm_snapshot_data').createSync();
    globals.fs.file('isolate_snapshot_data').createSync();
    // Project info
    globals.fs.file('pubspec.yaml').writeAsStringSync('name: hello');
    globals.fs.file('.packages').writeAsStringSync('\n');
    // Plist file
    globals.fs.file(globals.fs.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
      ..createSync(recursive: true);
    // App kernel
    environment.buildDir.childFile('app.dill').createSync(recursive: true);
    // Stub framework
    environment.buildDir.childFile('App').createSync();

    await const DebugIosApplicationBundle().build(environment);

    final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
    expect(frameworkDirectory.childFile('App'), exists);
    expect(frameworkDirectory.childFile('Info.plist'), exists);

    final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
    expect(assetDirectory.childFile('kernel_blob.bin'), exists);
    expect(assetDirectory.childFile('AssetManifest.json'), exists);
    expect(assetDirectory.childFile('vm_snapshot_data'), exists);
    expect(assetDirectory.childFile('isolate_snapshot_data'), exists);
  }, overrides: <Type, Generator>{
    Artifacts: () => MockArtifacts(),
  }));

  test('ReleaseIosApplicationBundle', () => testbed.run(() async {
    environment.defines[kBuildMode] = 'release';

    // Project info
    globals.fs.file('pubspec.yaml').writeAsStringSync('name: hello');
    globals.fs.file('.packages').writeAsStringSync('\n');
    // Plist file
    globals.fs.file(globals.fs.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
      ..createSync(recursive: true);

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
  }));
}

class MockArtifacts extends Mock implements Artifacts {}
