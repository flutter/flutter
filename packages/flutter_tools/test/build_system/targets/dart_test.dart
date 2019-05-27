// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('kernel_snapshot', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
          targetPlatform: TargetPlatform.darwin_x64,
          buildMode: BuildMode.debug,
        );
        buildSystem = const BuildSystem(<Target>[
          kernelSnapshot,
        ]);
        fs.file('.packages')
          ..createSync()
          ..writeAsStringSync('''
# Generated
flutter_tools:lib/''');
        fs.file('lib/foo.dart').createSync(recursive: true);
        fs.file('lib/bar.dart').createSync();
        fs.file('lib/fizz').createSync();
      }, overrides: <Type, Generator>{
        KernelCompilerFactory: () => FakeKernelCompilerFactory(),
      });
    });

    test('Produces correct output directory', () => testbed.run(() async {
      await buildSystem.build('kernel_snapshot', environment);

      expect(fs.file('build/debug/main.app.dill').existsSync(), true);
    }));
  });
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
