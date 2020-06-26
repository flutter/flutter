// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/testbed.dart';

const String _kInputPrefix = 'bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.framework';
const String _kOutputPrefix = 'FlutterMacOS.framework';

final List<String> inputs = <String>[
  '$_kInputPrefix/FlutterMacOS',
  // Headers
  '$_kInputPrefix/Headers/FlutterDartProject.h',
  '$_kInputPrefix/Headers/FlutterEngine.h',
  '$_kInputPrefix/Headers/FlutterViewController.h',
  '$_kInputPrefix/Headers/FlutterBinaryMessenger.h',
  '$_kInputPrefix/Headers/FlutterChannels.h',
  '$_kInputPrefix/Headers/FlutterCodecs.h',
  '$_kInputPrefix/Headers/FlutterMacros.h',
  '$_kInputPrefix/Headers/FlutterPluginMacOS.h',
  '$_kInputPrefix/Headers/FlutterPluginRegistrarMacOS.h',
  '$_kInputPrefix/Headers/FlutterMacOS.h',
  // Modules
  '$_kInputPrefix/Modules/module.modulemap',
  // Resources
  '$_kInputPrefix/Resources/icudtl.dat',
  '$_kInputPrefix/Resources/Info.plist',
  // Ignore Versions folder for now
  'packages/flutter_tools/lib/src/build_system/targets/macos.dart',
];

void main() {
  Testbed testbed;
  Environment environment;
  Platform platform;

  setUp(() {
    platform = FakePlatform(operatingSystem: 'macos', environment: <String, String>{});
    testbed = Testbed(setup: () {
      environment = Environment.test(
        globals.fs.currentDirectory,
        defines: <String, String>{
            kBuildMode: 'debug',
            kTargetPlatform: 'darwin-x64',
        },
        inputs: <String, String>{},
        artifacts: MockArtifacts(),
        processManager: FakeProcessManager.any(),
        logger: globals.logger,
        fileSystem: globals.fs,
        engineVersion: '2'
      );
      environment.buildDir.createSync(recursive: true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Platform: () => platform,
    });
  });

  test('Copies files to correct cache directory', () => testbed.run(() async {
    for (final String input in inputs) {
      globals.fs.file(input).createSync(recursive: true);
    }
    // Create output directory so we can test that it is deleted.
    environment.outputDir.childDirectory(_kOutputPrefix)
        .createSync(recursive: true);

    when(globals.processManager.run(any)).thenAnswer((Invocation invocation) async {
      final List<String> arguments = invocation.positionalArguments.first as List<String>;
      final String sourcePath = arguments[arguments.length - 2];
      final String targetPath = arguments.last;
      final Directory source = globals.fs.directory(sourcePath);
      final Directory target = globals.fs.directory(targetPath);

      for (final FileSystemEntity entity in source.listSync(recursive: true)) {
        if (entity is File) {
          final String relative = globals.fs.path.relative(entity.path, from: source.path);
          final String destination = globals.fs.path.join(target.path, relative);
          if (!globals.fs.file(destination).parent.existsSync()) {
            globals.fs.file(destination).parent.createSync();
          }
          entity.copySync(destination);
        }
      }
      return FakeProcessResult()..exitCode = 0;
    });
    await const DebugUnpackMacOS().build(environment);

    expect(globals.fs.directory(_kOutputPrefix).existsSync(), true);
    for (final String path in inputs) {
      expect(globals.fs.file(path.replaceFirst(_kInputPrefix, _kOutputPrefix)), exists);
    }
  }));

  test('debug macOS application fails if App.framework missing', () => testbed.run(() async {
    final String inputKernel = globals.fs.path.join(environment.buildDir.path, 'app.dill');
    globals.fs.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    expect(() async => await const DebugMacOSBundleFlutterAssets().build(environment),
        throwsException);
  }));

  test('debug macOS application creates correctly structured framework', () => testbed.run(() async {
    environment.inputs[kBundleSkSLPath] = 'bundle.sksl';
    globals.fs.file('bin/cache/artifacts/engine/darwin-x64/vm_isolate_snapshot.bin')
      .createSync(recursive: true);
    globals.fs.file('bin/cache/artifacts/engine/darwin-x64/isolate_snapshot.bin')
      .createSync(recursive: true);
    globals.fs.file('${environment.buildDir.path}/App.framework/App')
      .createSync(recursive: true);
    // sksl bundle
    globals.fs.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, Object>{
        'engineRevision': '2',
        'platform': 'ios',
        'data': <String, Object>{
          'A': 'B',
        }
      }
    ));

    final String inputKernel = '${environment.buildDir.path}/app.dill';
    globals.fs.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    await const DebugMacOSBundleFlutterAssets().build(environment);

    expect(globals.fs.file(
      'App.framework/Versions/A/Resources/flutter_assets/kernel_blob.bin').readAsStringSync(),
      'testing',
    );
    expect(globals.fs.file(
      'App.framework/Versions/A/Resources/Info.plist').readAsStringSync(),
      contains('io.flutter.flutter.app'),
    );
    expect(globals.fs.file(
      'App.framework/Versions/A/Resources/flutter_assets/vm_snapshot_data'),
      exists,
    );
    expect(globals.fs.file(
      'App.framework/Versions/A/Resources/flutter_assets/isolate_snapshot_data'),
      exists,
    );

    final File skslFile = globals.fs.file('App.framework/Versions/A/Resources/flutter_assets/io.flutter.shaders.json');

    expect(skslFile, exists);
    expect(skslFile.readAsStringSync(), '{"data":{"A":"B"}}');
  }));

  test('release/profile macOS application has no blob or precompiled runtime', () => testbed.run(() async {
    globals.fs.file('bin/cache/artifacts/engine/darwin-x64/vm_isolate_snapshot.bin')
      .createSync(recursive: true);
    globals.fs.file('bin/cache/artifacts/engine/darwin-x64/isolate_snapshot.bin')
      .createSync(recursive: true);
    globals.fs.file('${environment.buildDir.path}/App.framework/App')
      .createSync(recursive: true);

    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');

    expect(globals.fs.file(
      'App.framework/Versions/A/Resources/flutter_assets/kernel_blob.bin'),
      isNot(exists),
    );
    expect(globals.fs.file(
      'App.framework/Versions/A/Resources/flutter_assets/vm_snapshot_data'),
      isNot(exists),
    );
    expect(globals.fs.file(
      'App.framework/Versions/A/Resources/flutter_assets/isolate_snapshot_data'),
      isNot(exists),
    );
  }));

  test('release/profile macOS application updates when App.framework updates', () => testbed.run(() async {
    globals.fs.file('bin/cache/artifacts/engine/darwin-x64/vm_isolate_snapshot.bin')
      .createSync(recursive: true);
    globals.fs.file('bin/cache/artifacts/engine/darwin-x64/isolate_snapshot.bin')
      .createSync(recursive: true);
    final File inputFramework = globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'App.framework', 'App'))
      ..createSync(recursive: true)
      ..writeAsStringSync('ABC');

    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');
    final File outputFramework = globals.fs.file(globals.fs.path.join(environment.outputDir.path, 'App.framework', 'App'));

    expect(outputFramework.readAsStringSync(), 'ABC');

    inputFramework.writeAsStringSync('DEF');
    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');

    expect(outputFramework.readAsStringSync(), 'DEF');
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockGenSnapshot extends Mock implements GenSnapshot {}
class MockXcode extends Mock implements Xcode {}
class MockArtifacts extends Mock implements Artifacts {}
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
