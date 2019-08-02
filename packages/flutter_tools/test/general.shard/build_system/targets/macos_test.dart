// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/testbed.dart';

final List<File> inputs = <File>[
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/FlutterMacOS'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEOpenGLContextHandling.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEReshapeListener.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEView.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEViewController.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterBinaryMessenger.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterChannels.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterCodecs.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterMacOS.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterPluginMacOS.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterPluginRegisrarMacOS.h'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Modules/module.modulemap'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Resources/icudtl.dat'),
  fs.file('bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework/Resources/info.plist'),
  fs.file('packages/flutter_tools/lib/src/build_system/targets/macos.dart'),
];

void main() {
  Testbed testbed;
  Environment environment;
  MockPlatform mockPlatform;

  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = '';
  });

  setUp(() {
    mockPlatform = MockPlatform();
    when(mockPlatform.isWindows).thenReturn(false);
    when(mockPlatform.isMacOS).thenReturn(true);
    when(mockPlatform.isLinux).thenReturn(false);
    when(mockPlatform.environment).thenReturn(const <String, String>{});
    testbed = Testbed(setup: () {
      environment = Environment(
        projectDir: fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: 'debug',
          kTargetPlatform: 'darwin-x64',
        }
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Platform: () => mockPlatform,
    });
  });

  test('Copies files to correct cache directory', () => testbed.run(() async {
    for (File input in inputs) {
      input.createSync(recursive: true);
    }
    when(processManager.run(any)).thenAnswer((Invocation invocation) async {
      final List<String> arguments = invocation.positionalArguments.first;
      final Directory source = fs.directory(arguments[arguments.length - 2]);
      final Directory target = fs.directory(arguments.last)
        ..createSync(recursive: true);
      for (FileSystemEntity entity in source.listSync(recursive: true)) {
        if (entity is File) {
          final String relative = fs.path.relative(entity.path, from: source.path);
          final String destination = fs.path.join(target.path, relative);
          if (!fs.file(destination).parent.existsSync()) {
            fs.file(destination).parent.createSync();
          }
          entity.copySync(destination);
        }
      }
      return FakeProcessResult()..exitCode = 0;
    });
    await const UnpackMacOS().build(<File>[], environment);

    expect(fs.directory('macos/Flutter/ephemeral/FlutterMacOS.framework').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/FlutterMacOS').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Headers/FLEViewController.h').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Headers/FlutterBinaryMessenger.h').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Headers/FlutterChannels.h').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Headers/FlutterCodecs.h').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Headers/FlutterMacOS.h').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Headers/FlutterPluginMacOS.h').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Headers/FlutterPluginRegisrarMacOS.h').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Modules/module.modulemap').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Resources/icudtl.dat').existsSync(), true);
    expect(fs.file('macos/Flutter/ephemeral/FlutterMacOS.framework/Resources/info.plist').existsSync(), true);
  }));

  test('debug macOS application copies kernel blob', () => testbed.run(() async {
    final String inputKernel = fs.path.join(environment.buildDir.path, 'app.dill');
    final String outputKernel = fs.path.join(environment.buildDir.path, 'flutter_assets', 'kernel_blob.bin');
    fs.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    await const DebugMacOSApplication().build(<File>[], environment);

    expect(fs.file(outputKernel).readAsStringSync(), 'testing');
  }));

  test('profile macOS application copies kernel blob', () => testbed.run(() async {
    final String inputKernel = fs.path.join(environment.buildDir.path, 'app.dill');
    final String outputKernel = fs.path.join(environment.buildDir.path, 'flutter_assets', 'kernel_blob.bin');
    fs.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    await const ProfileMacOSApplication().build(<File>[], environment);

    expect(fs.file(outputKernel).readAsStringSync(), 'testing');
  }));

  test('release macOS application copies kernel blob', () => testbed.run(() async {
    final String inputKernel = fs.path.join(environment.buildDir.path, 'app.dill');
    final String outputKernel = fs.path.join(environment.buildDir.path, 'flutter_assets', 'kernel_blob.bin');
    fs.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    await const ReleaseMacOSApplication().build(<File>[], environment);

    expect(fs.file(outputKernel).readAsStringSync(), 'testing');
  }));

  // Changing target names will require a corresponding update in flutter_tools/bin/macos_build_flutter_assets.sh.
  test('Target names match those expected by bin scripts', () => testbed.run(() async {
    expect(const DebugMacOSApplication().name, 'debug_macos_application');
    expect(const ProfileMacOSApplication().name, 'profile_macos_application');
    expect(const ReleaseMacOSApplication().name, 'release_macos_application');
  }));


  test('DebugMacOSPodInstall throws if missing build mode', () => testbed.run(() async {
    expect(() => const DebugMacOSPodInstall().build(<File>[], environment),
        throwsA(isInstanceOf<MissingDefineException>()));
  }));

  test('DebugMacOSPodInstall skips if podfile does not exist', () => testbed.run(() async {
    await const DebugMacOSPodInstall().build(<File>[], Environment(
      projectDir: fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug'
      }
    ));

    verifyNever(cocoaPods.processPods(
      xcodeProject: anyNamed('xcodeProject'),
      engineDir: anyNamed('engineDir'),
      isSwift: true,
      dependenciesChanged: true));
  }, overrides: <Type, Generator>{
    CocoaPods: () => MockCocoaPods(),
  }));

  test('DebugMacOSPodInstall invokes processPods with podfile', () => testbed.run(() async {
    fs.file(fs.path.join('macos', 'Podfile')).createSync(recursive: true);
    await const DebugMacOSPodInstall().build(<File>[], Environment(
        projectDir: fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: 'debug'
        }
    ));

    verify(cocoaPods.processPods(
      xcodeProject: anyNamed('xcodeProject'),
      engineDir: anyNamed('engineDir'),
      isSwift: true,
      dependenciesChanged: true)).called(1);
  }, overrides: <Type, Generator>{
    CocoaPods: () => MockCocoaPods(),
  }));

  test('DummyMacOSAotAssembly invokes silly build script', () => testbed.run(() async {
    when(processManager.run(<String>[
      fs.path.join(environment.flutterRootDir.path, 'packages', 'flutter_tools', 'bin', 'hack_script.sh')
    ], runInShell: true)).thenAnswer((Invocation _) async {
      return FakeProcessResult()..exitCode = 0;
    });

    await const DummyMacOSAotAssembly().build(<File>[], environment);

    expect(fs.file(fs.path.join(environment.projectDir.path, 'macos', 'Flutter',
        'ephemeral', 'App.framework', 'App')).existsSync(), true);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('DummyMacOSAotAssembly throws exception if script does not exit cleanly', () => testbed.run(() async {
    when(processManager.run(<String>[
      fs.path.join(environment.flutterRootDir.path, 'packages', 'flutter_tools', 'bin', 'hack_script.sh')
    ], runInShell: true)).thenAnswer((Invocation _) async {
      return FakeProcessResult()..exitCode = 1;
    });

    expect(const DummyMacOSAotAssembly().build(<File>[], environment),
        throwsA(isInstanceOf<Exception>()));
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(),
  }));

  test('MacOSAotAssembly requires BuildMode', () => testbed.run(() async {
    expect(const MacOSAotAssembly().build(<File>[], environment..defines.remove(kBuildMode)),
        throwsA(isInstanceOf<MissingDefineException>()));
  }));

  test('MacOSAotAssembly requires TargePlatform', () => testbed.run(() async {
    expect(const MacOSAotAssembly().build(<File>[], environment..defines.remove(kTargetPlatform)),
        throwsA(isInstanceOf<MissingDefineException>()));
  }));

  test('MacOSAotAssembly requires TargetPlatform.darwin_x64', () => testbed.run(() async {
    expect(const MacOSAotAssembly().build(<File>[], environment..defines[kTargetPlatform] = 'android_arm'),
        throwsA(isInstanceOf<Exception>()));
  }));

  test('MacOSAotAssembly requires BuildMode.profile or BuildMode.release', () => testbed.run(() async {
    expect(const MacOSAotAssembly().build(<File>[], environment..defines[kBuildMode] = 'debug'),
        throwsA(isInstanceOf<Exception>()));
  }));

  test('MacOSAotAssembly invokes gen_snapshot and clang with correct arguments', () => testbed.run(() async {
    fs.file('.packages').writeAsStringSync('''
foo:lib/
sky_engine:/
''');
    fs.file(environment.buildDir.childFile('app.dill')).createSync(recursive: true);
    fs.file(fs.path.join('lib', 'ui', 'ui.dart')).createSync(recursive: true);
    fs.file(fs.path.join('sdk_ext', 'vmservice_io.dart')).createSync(recursive: true);
    when(genSnapshot.run(
      snapshotType: anyNamed('snapshotType'),
      iosArch: IOSArch.x86_64,
      additionalArgs: <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=/macos/Flutter/ephemeral/snapshot_assembly.S',
        environment.buildDir.childFile('app.dill').path,
      ],
    )).thenAnswer((Invocation _) async {
      return 0;
    });
    when(xcode.cc(<String>[
      '-arch', 'x86_64',
      '-c', '/macos/Flutter/ephemeral/snapshot_assembly.S',
      '-o', '/macos/Flutter/ephemeral/snapshot_assembly.o'
    ])).thenAnswer((Invocation _) async {
      return RunResult(FakeProcessResult()..exitCode = 0, _.positionalArguments.first);
    });
    when(xcode.clang(<String>[
      '-arch', 'x86_64',
      '-dynamiclib',
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
      '-o', '/macos/Flutter/ephemeral/App.framework/App',
      '/macos/Flutter/ephemeral/snapshot_assembly.o',
    ])).thenAnswer((Invocation _) async {
      return RunResult(FakeProcessResult()..exitCode = 0, _.positionalArguments.first);
    });
    when(xcode.dsymutil(<String>[
      '/macos/Flutter/ephemeral/App.framework/App',
      '-o', '/macos/Flutter/ephemeral/App.framework.dSYM.noindex',
    ])).thenAnswer((Invocation _) async {
      return RunResult(FakeProcessResult()..exitCode = 0, _.positionalArguments.first);
    });

    await const MacOSAotAssembly().build(<File>[], environment..defines[kBuildMode] = 'release');
  }, overrides: <Type, Generator>{
    GenSnapshot: () => MockGenSnapshot(),
    Xcode: () => MockXCode(),
  }));
}

class MockPlatform extends Mock implements Platform {}
class MockCocoaPods extends Mock implements CocoaPods {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockGenSnapshot extends Mock implements GenSnapshot {}
class MockXCode extends Mock implements Xcode {}
class FakeProcessResult implements ProcessResult {
  @override
  int exitCode;

  @override
  int pid = 0;

  @override
  String stderr = '';

  @override
  String stdout = '';
}
