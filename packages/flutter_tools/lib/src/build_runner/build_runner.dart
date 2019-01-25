// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../project.dart';

/// The [BuildRunnerFactory] instance.
BuildRunnerFactory get buildRunnerFactory => context[BuildRunnerFactory];

/// Whether to attempt to build a flutter project using build* libraries.
///
/// This requires both an experimental opt in via the environment variable
/// 'FLUTTER_EXPERIMENTAL_BUILD' and that the project itself has a
/// dependency on the package 'flutter_build' and 'build_runner.'
FutureOr<bool> get experimentalBuildEnabled async {
  if (_experimentalBuildEnabled != null) {
    return _experimentalBuildEnabled;
  }
  final bool flagEnabled = platform.environment['FLUTTER_EXPERIMENTAL_BUILD']?.toLowerCase() == 'true';
  if (!flagEnabled) {
    return _experimentalBuildEnabled = false;
  }
  final FlutterProject flutterProject = await FlutterProject.current();
  final Map<String, Uri> packages = PackageMap(flutterProject.packagesFile.path).map;
  return _experimentalBuildEnabled = packages.containsKey('flutter_build') && packages.containsKey('build_runner');
}
bool _experimentalBuildEnabled;

@visibleForTesting
set experimentalBuildEnabled(bool value) {
  _experimentalBuildEnabled = value;
}

/// An injectable factory to create instances of [BuildRunner].
class BuildRunnerFactory {
  const BuildRunnerFactory();

  /// Creates a new [BuildRunner] instance.
  BuildRunner create() {
    return BuildRunner();
  }
}

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
class BuildRunner {

  /// Run a build_runner build and return the resulting .packages and dill file.
  ///
  /// The defines of the build command are the arguments required in the
  /// flutter_build kernel builder.
  Future<BuildResult> build({
    @required bool aot,
    @required bool linkPlatformKernelIn,
    @required bool trackWidgetCreation,
    @required bool targetProductVm,
    @required String mainPath,
    @required List<String> extraFrontEndOptions,
  }) async {
    final FlutterProject flutterProject = await FlutterProject.current();
    final String frontendServerPath = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    final String pubExecutable = fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk','bin', 'pub');
    final String sdkRoot = artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath);
    final String engineDartBinaryPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final String packagesPath = flutterProject.packagesFile.absolute.path;
    final Process process = await processManager.start(<String>[
      '$pubExecutable',
      'run',
      'build_runner',
      'build',
      '--define', 'flutter_build|kernel=disabled=false',
      '--define', 'flutter_build|kernel=aot=$aot',
      '--define', 'flutter_build|kernel=linkPlatformKernelIn=$linkPlatformKernelIn',
      '--define', 'flutter_build|kernel=trackWidgetCreation=$trackWidgetCreation',
      '--define', 'flutter_build|kernel=targetProductVm=$targetProductVm',
      '--define', 'flutter_build|kernel=mainPath=$mainPath',
      '--define', 'flutter_build|kernel=packagesPath=$packagesPath',
      '--define', 'flutter_build|kernel=sdkRoot=$sdkRoot',
      '--define', 'flutter_build|kernel=frontendServerPath=$frontendServerPath',
      '--define', 'flutter_build|kernel=engineDartBinaryPath=$engineDartBinaryPath',
      '--define', 'flutter_build|kernel=extraFrontEndOptions=${extraFrontEndOptions ?? const <String>[]}',
    ]);
    process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(_handleOutput);
    process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(_handleError);
    final int exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('build_runner exited with non-zero exit code: $exitCode');
    }
    /// We don't check for this above because it might be generated for the
    /// first time by invoking the build.
    final Directory dartTool = flutterProject.dartTool;
    final String projectName = flutterProject.manifest.appName;
    final Directory generatedDirectory = dartTool
      .absolute
      .childDirectory('build')
      .childDirectory('generated')
      .childDirectory(projectName);
    if (!await generatedDirectory.exists()) {
      throw Exception('build_runner cannot find generated directory');
    }
    final String relativeMain = fs.path.relative(mainPath, from: flutterProject.directory.path);
    final File packagesFile = fs.file(
      fs.path.join(generatedDirectory.path,  fs.path.setExtension(relativeMain, '.packages'))
    );
    final File dillFile = fs.file(
      fs.path.join(generatedDirectory.path, fs.path.setExtension(relativeMain, '.app.dill'))
    );
    if (!await packagesFile.exists() || !await dillFile.exists()) {
      throw Exception('build_runner did not produce output at expected location: ${dillFile.path} missing');
    }
    return BuildResult(packagesFile, dillFile);
  }

  void _handleOutput(String line) {
    printTrace(line);
  }

  void _handleError(String line) {
    printError(line);
  }
}

class BuildResult {
  const BuildResult(this.packagesFile, this.dillFile);

  final File packagesFile;
  final File dillFile;
}
