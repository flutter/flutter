// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/testbed.dart';

const String _kInputPrefix = 'bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework';
const String _kOutputPrefix = 'macos/Flutter/ephemeral/FlutterMacOS.framework';

final List<File> inputs = <File>[
  fs.file('$_kInputPrefix/FlutterMacOS'),
  // Headers
  fs.file('$_kInputPrefix/Headers/FlutterDartProject.h'),
  fs.file('$_kInputPrefix/Headers/FlutterEngine.h'),
  fs.file('$_kInputPrefix/Headers/FlutterViewController.h'),
  fs.file('$_kInputPrefix/Headers/FlutterBinaryMessenger.h'),
  fs.file('$_kInputPrefix/Headers/FlutterChannels.h'),
  fs.file('$_kInputPrefix/Headers/FlutterCodecs.h'),
  fs.file('$_kInputPrefix/Headers/FlutterMacros.h'),
  fs.file('$_kInputPrefix/Headers/FlutterPluginMacOS.h'),
  fs.file('$_kInputPrefix/Headers/FlutterPluginRegistrarMacOS.h'),
  fs.file('$_kInputPrefix/Headers/FlutterMacOS.h'),
  // Modules
  fs.file('$_kInputPrefix/Modules/module.modulemap'),
  // Resources
  fs.file('$_kInputPrefix/Resources/icudtl.dat'),
  fs.file('$_kInputPrefix/Resources/Info.plist'),
  // Ignore Versions folder for now
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

    expect(fs.directory('$_kOutputPrefix').existsSync(), true);
    for (File file in inputs) {
      expect(fs.file(file.path.replaceFirst(_kInputPrefix, _kOutputPrefix)).existsSync(), true);
    }
  }));

  test('debug macOS application fails if App.framework missing', () => testbed.run(() async {
    final String inputKernel = fs.path.join(environment.buildDir.path, 'app.dill');
    fs.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    expect(() async => await const DebugBundleFlutterAssets().build(<File>[], environment),
        throwsA(isInstanceOf<Exception>()));
  }));

  test('debug macOS application copies kernel blob', () => testbed.run(() async {
    fs.file(fs.path.join('bin', 'cache', 'artifacts', 'engine', 'darwin-x64',
        'vm_isolate_snapshot.bin')).createSync(recursive: true);
    fs.file(fs.path.join('bin', 'cache', 'artifacts', 'engine', 'darwin-x64',
        'isolate_snapshot.bin')).createSync(recursive: true);
    fs.file(fs.path.join(environment.buildDir.path, 'App.framework', 'App'))
        ..createSync(recursive: true);
    final String frameworkPath = fs.path.join(environment.projectDir.path,
        'macos', 'Flutter', 'ephemeral', 'App.framework');
    final String inputKernel = fs.path.join(environment.buildDir.path, 'app.dill');
    fs.directory(frameworkPath).createSync(recursive: true);
    final String outputKernel = fs.path.join(frameworkPath, 'Resources',
        'flutter_assets', 'kernel_blob.bin');
    final String outputPlist = fs.path.join(frameworkPath, 'Resources', 'Info.plist');
    fs.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    await const DebugBundleFlutterAssets().build(<File>[], environment);

    expect(fs.file(outputKernel).readAsStringSync(), 'testing');
    expect(fs.file(outputPlist).readAsStringSync(), contains('io.flutter.flutter.app'));
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
