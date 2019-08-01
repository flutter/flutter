// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/testbed.dart';

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
      );
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
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Platform: () => mockPlatform,
    });
  });

  test('Copies files to correct cache directory', () => testbed.run(() async {
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

  test('b', () => testbed.run(() async {

  }));

}

class MockPlatform extends Mock implements Platform {}
class MockCocoaPods extends Mock implements CocoaPods {}
class MockProcessManager extends Mock implements ProcessManager {}
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


