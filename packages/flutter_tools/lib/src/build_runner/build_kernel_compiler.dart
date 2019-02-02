// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../compile.dart';
import '../globals.dart';
import 'build_runner.dart';

/// An implementation of the [KernelCompiler] which delegates to build_runner.
///
/// Only a subset of the arguments provided to the [KernelCompiler] are
/// supported here. Using the build pipeline implies a fixed multiroot
/// filesystem and requires a pubspec.
///
/// This is only safe to use if [experimentalBuildEnabled] is true.
class BuildKernelCompiler implements KernelCompiler {
  const BuildKernelCompiler();

  @override
  Future<CompilerOutput> compile({
    String mainPath,
    String outputFilePath,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    bool targetProductVm = false,
    // These arguments are currently unused.
    String sdkRoot,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
  }) async {
    if (fileSystemRoots != null || fileSystemScheme != null || depFilePath != null || targetModel != null || sdkRoot != null || packagesPath != null) {
      printTrace('fileSystemRoots, fileSystemScheme, depFilePath, targetModel,'
        'sdkRoot, packagesPath are not supported when using the experimental '
        'build* pipeline');
    }
    final BuildRunner buildRunner = buildRunnerFactory.create();
    try {
      final BuildResult buildResult = await buildRunner.build(
        aot: aot,
        linkPlatformKernelIn: linkPlatformKernelIn,
        trackWidgetCreation: trackWidgetCreation,
        mainPath: mainPath,
        targetProductVm: targetProductVm,
        extraFrontEndOptions: extraFrontEndOptions
      );
      final File outputFile = fs.file(outputFilePath);
      if (!await outputFile.exists()) {
        await outputFile.create();
      }
      await outputFile.writeAsBytes(await buildResult.dillFile.readAsBytes());
      return CompilerOutput(outputFilePath, 0);
    } on Exception catch (err) {
      printError('Compilation Failed: $err');
      return const CompilerOutput(null, 1);
    }
  }
}
