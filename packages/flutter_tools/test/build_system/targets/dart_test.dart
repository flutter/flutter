// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('dart rules', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
          defines: <String, String>{
            kBuildMode: getNameForBuildMode(BuildMode.profile),
          }
        );
        buildSystem = BuildSystem(<String, Target>{
          kernelSnapshot.name: kernelSnapshot,
          aotElf.name: aotElf,
        });
        fs.file('.packages')
          ..createSync()
          ..writeAsStringSync('''
# Generated
sky_engine:file:///cache/pkg/sky_engine/lib/
flutter_tools:lib/''');
        fs.file(fs.path.join(cacheDir.path, 'pkg', 'sky_engine', 'lib', 'ui', 'ui.dart')).createSync(recursive: true);
        fs.file(fs.path.join(cacheDir.path, 'pkg', 'sky_engine', 'sdk_ext', 'vmservice_io.dart')).createSync(recursive: true);
        fs.file(fs.path.join('lib', 'foo.dart')).createSync(recursive: true);
        fs.file(fs.path.join('lib', 'bar.dart')).createSync();
        fs.file(fs.path.join('lib', 'fizz')).createSync();
        fs.file(fs.path.join('cache', 'engine', 'common', 'flutter_patched_sdk', 'platform_strong.dill')).createSync(recursive: true);
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
      expect(buildSystem.build('kernel_snapshot', environment..defines.remove(kBuildMode), const BuildSystemConfig()),
        throwsA(isInstanceOf<MissingDefineException>()),
      );
    }));

    test('aot_elf Produces correct output directory', () => testbed.run(() async {
      await buildSystem.build('aot_elf', environment, const BuildSystemConfig());

      expect(fs.file(fs.path.join(environment.buildDir.path, 'main.app.dill')).existsSync(), true);
      expect(fs.file(fs.path.join(environment.buildDir.path, 'app.so')).existsSync(), true);
    }));

    test('aot_elf throws error if missing build mode', () => testbed.run(() async {
      expect(buildSystem.build('aot_elf', environment..defines.remove(kBuildMode), const BuildSystemConfig()),
        throwsA(isInstanceOf<MissingDefineException>()),
      );
    }));
  });
}

class FakeGenSnapshot implements GenSnapshot {
  @override
  Future<int> run({SnapshotType snapshotType, IOSArch iosArch, Iterable<String> additionalArgs = const <String>[]}) async {
    fs.file(additionalArgs.last).parent.childFile('app.so').createSync();
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
