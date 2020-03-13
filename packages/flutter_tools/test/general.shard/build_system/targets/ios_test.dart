// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

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
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(operatingSystem: 'macos', environment: const <String, String>{}),
    });
  });

  test('DebugUniveralFramework creates expected binary with arm64 only arch', () => testbed.run(() async {
    environment.defines[kIosArchs] = 'arm64';
    processManager = FakeProcessManager.list(<FakeCommand>[
      // Create iphone stub.
      const FakeCommand(command: <String>['xcrun', '--sdk', 'iphoneos', '--show-sdk-path']),
      FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-x',
        'c',
         // iphone only gets 64 bit arch based on kIosArchs
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
      .createSync(recursive: true);
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
  }));

  test('UnpackIOSEngine throws without build mode', () => testbed.run(() async {
    expect(const UnpackIOSEngine().build(environment),
      throwsA(isA<MissingDefineException>()));
  }));

  test('UnpackIOSEngine for regular project', () => testbed.run(() async {
    environment.defines[kBuildMode] = getNameForBuildMode(BuildMode.profile);
    environment.outputDir.createSync();
    environment.buildDir.createSync(recursive: true);
    globals.fs.directory('bin/cache/artifacts/engine/ios-profile/Flutter.framework')
      .createSync(recursive: true);
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'cp',
        '-r',
        '--',
        'bin/cache/artifacts/engine/ios-profile/Flutter.framework',
        '/',
      ]),
      const FakeCommand(command: <String>[
        'cp',
        '-r',
        '--',
        'bin/cache/artifacts/engine/ios-profile/Flutter.podspec',
        '/',
      ]),
    ]);

    await const UnpackIOSEngine().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
    Platform: () => FakePlatform(operatingSystem: 'macos'),
  }));

  test('UnpackIOSEngine for module', () => testbed.run(() async {
    environment.defines[kBuildMode] = getNameForBuildMode(BuildMode.profile);
    environment.outputDir.createSync();
    environment.buildDir.createSync(recursive: true);
    globals.fs.file('bin/cache/artifacts/engine/ios-profile/Flutter.framework/a')
      ..createSync(recursive: true)
      ..writeAsStringSync('A');
    globals.fs.file('pubspec.yaml')
      .writeAsStringSync('''
flutter:
  module:
    androidPackage: com.example.iosadd2appflutter
    iosBundleIdentifier: com.example.iosAdd2appFlutter
''');
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'cp',
        '-r',
        '--',
        'bin/cache/artifacts/engine/ios-profile/Flutter.framework',
        '/engine',
      ]),
      const FakeCommand(command: <String>[
        'cp',
        '-r',
        '--',
        'bin/cache/artifacts/engine/ios-profile/Flutter.podspec',
        '/engine',
      ]),
    ]);

    await const UnpackIOSEngine().build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
  }));
}

class MockArtifacts extends Mock implements Artifacts {}
