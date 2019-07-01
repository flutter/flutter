// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('dart rules', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      testbed = Testbed(setup: () {
        environment = Environment(
          projectDir: fs.currentDirectory,
          defines: <String, String>{
            kBuildMode: getNameForBuildMode(BuildMode.profile),
          }
        );
        buildSystem = BuildSystem(<String, Target>{
          kernelSnapshot.name: kernelSnapshot,
          aotElf.name: aotElf,
        });
        HostPlatform hostPlatform;
        if (platform.isWindows) {
          hostPlatform = HostPlatform.windows_x64;
        } else if (platform.isLinux) {
          hostPlatform = HostPlatform.linux_x64;
        } else if (platform.isMacOS) {
           hostPlatform = HostPlatform.darwin_x64;
        } else {
          assert(false);
        }
         final String skyEngineLine = platform.isWindows
            ? r'sky_engine:file:///C:/bin/cache/pkg/sky_engine/lib/'
            : 'sky_engine:file:///bin/cache/pkg/sky_engine/lib/';
        fs.file('.packages')
          ..createSync()
          ..writeAsStringSync('''
# Generated
$skyEngineLine
flutter_tools:lib/''');
        fs.file(fs.path.join('bin', 'cache', 'pkg', 'sky_engine', 'lib', 'ui', 'ui.dart')).createSync(recursive: true);
        fs.file(fs.path.join('bin', 'cache', 'pkg', 'sky_engine', 'sdk_ext', 'vmservice_io.dart')).createSync(recursive: true);
        fs.file(fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart')).createSync(recursive: true);
        fs.file(fs.path.join('bin', 'cache', 'artifacts', 'engine', getNameForHostPlatform(hostPlatform), 'frontend_server.dart.snapshot')).createSync(recursive: true);
        fs.file(fs.path.join('bin', 'cache', 'artifacts', 'engine', 'android-arm-profile', getNameForHostPlatform(hostPlatform), 'gen_snapshot')).createSync(recursive: true);
        fs.file(fs.path.join('bin', 'cache', 'artifacts', 'engine', 'common', 'flutter_patched_sdk', 'platform_strong.dill')).createSync(recursive: true);
        fs.file(fs.path.join('lib', 'foo.dart')).createSync(recursive: true);
        fs.file(fs.path.join('lib', 'bar.dart')).createSync();
        fs.file(fs.path.join('lib', 'fizz')).createSync();
      }, overrides: <Type, Generator>{
        KernelCompilerFactory: () => FakeKernelCompilerFactory(),
        GenSnapshot: () => FakeGenSnapshot(),
      });
    });

    test('kernel_snapshot Produces correct output directory', () => testbed.run(() async {
      await buildSystem.build('kernel_snapshot', environment, const BuildSystemConfig());

      expect(fs.file(fs.path.join(environment.buildDir.path,'main.app.dill')).existsSync(), true);
    }));

    test('kernel_snapshot throws error if missing build mode', () => testbed.run(() async {
      final BuildResult result = await buildSystem.build('kernel_snapshot', environment..defines.remove(kBuildMode), const BuildSystemConfig());

      expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
    }));

    test('aot_elf Produces correct output directory', () => testbed.run(() async {
      await buildSystem.build('aot_elf', environment, const BuildSystemConfig());

      expect(fs.file(fs.path.join(environment.buildDir.path, 'main.app.dill')).existsSync(), true);
      expect(fs.file(fs.path.join(environment.buildDir.path, 'app.so')).existsSync(), true);
    }));

    test('aot_elf throws error if missing build mode', () => testbed.run(() async {
      final BuildResult result = await buildSystem.build('aot_elf', environment..defines.remove(kBuildMode), const BuildSystemConfig());

      expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
    }));
  });
}

class FakeGenSnapshot implements GenSnapshot {
  @override
  Future<int> run({SnapshotType snapshotType, IOSArch iosArch, Iterable<String> additionalArgs = const <String>[]}) async {
    final Directory out = fs.file(additionalArgs.last).parent;
    out.childFile('app.so').createSync();
    out.childFile('gen_snapshot.d').createSync();
    out.childFile('snapshot.d.fingerprint').createSync();
    return 0;
  }
}

class FakeKernelCompilerFactory implements KernelCompilerFactory {
  FakeKernelCompiler kernelCompiler = FakeKernelCompiler();

  @override
  Future<KernelCompiler> create(FlutterProject flutterProject) async {
    return kernelCompiler;
  }
}

class FakeKernelCompiler implements KernelCompiler {
  @override
  Future<CompilerOutput> compile({
    String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    bool targetProductVm = false,
    String initializeFromDill}) async {
      fs.file(outputFilePath).createSync(recursive: true);
      return CompilerOutput(outputFilePath, 0, null);
  }
}
