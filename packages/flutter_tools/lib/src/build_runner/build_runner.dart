// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../project.dart';
import 'build_script_generator.dart';

/// The [BuildRunnerFactory] instance.
BuildRunnerFactory get buildRunnerFactory => context[BuildRunnerFactory];

/// Whether to attempt to build a flutter project using build* libraries.
///
/// This requires both an experimental opt in via the environment variable
/// 'FLUTTER_EXPERIMENTAL_BUILD' and that the project itself has a
/// dependency on the package 'flutter_build' and 'build_runner.'
bool get experimentalBuildEnabled {
  return _experimentalBuildEnabled ??= platform.environment['FLUTTER_EXPERIMENTAL_BUILD']?.toLowerCase() == 'true';
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
    await generateBuildScript();
    final FlutterProject flutterProject = await FlutterProject.current();
    final String frontendServerPath = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    final String sdkRoot = artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath);
    final String engineDartBinaryPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final String packagesPath = flutterProject.packagesFile.absolute.path;
    final String buildScript = flutterProject
        .dartTool
        .childDirectory('build')
        .childDirectory('entrypoint')
        .childFile('build.dart')
        .path;
    final String scriptPackagesPath = flutterProject
        .dartTool
        .childDirectory('flutter_tool')
        .childFile('.packages')
        .path;
    final String dartPath = fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');
    final Status status = logger.startProgress('running builders...', timeout: null);
    try {
      final Process buildProcess = await processManager.start(<String>[
        dartPath,
        '--packages=$scriptPackagesPath',
        buildScript,
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
      buildProcess
          .stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(printStatus);
      buildProcess
          .stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(printError);
      await buildProcess.exitCode;
    } finally {
      status.stop();
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
    if (!generatedDirectory.existsSync()) {
      throw Exception('build_runner cannot find generated directory');
    }
    final String relativeMain = fs.path.relative(mainPath, from: flutterProject.directory.path);
    final File packagesFile = fs.file(
      fs.path.join(generatedDirectory.path,  fs.path.setExtension(relativeMain, '.packages'))
    );
    final File dillFile = fs.file(
      fs.path.join(generatedDirectory.path, fs.path.setExtension(relativeMain, '.app.dill'))
    );
    if (!packagesFile.existsSync() || !dillFile.existsSync()) {
      throw Exception('build_runner did not produce output at expected location: ${dillFile.path} missing');
    }
    return BuildResult(packagesFile, dillFile);
  }

  /// Invalidates a generated build script by deleting it.
  ///
  /// Must be called any time a pubspec file update triggers a corresponding change
  /// in .packages.
  Future<void> invalidateBuildScript() async {
    final FlutterProject flutterProject = await FlutterProject.current();
    final File buildScript = flutterProject.dartTool
        .absolute
        .childDirectory('flutter_tool')
        .childFile('build.dart');
    if (!buildScript.existsSync()) {
      return;
    }
    await buildScript.delete();
  }

  // Generates a synthetic package under .dart_tool/flutter_tool which is in turn
  // used to generate a build script.
  Future<void> generateBuildScript() async {
    final FlutterProject flutterProject = await FlutterProject.current();
    final String generatedDirectory = fs.path.join(flutterProject.dartTool.path, 'flutter_tool');
    final String resultScriptPath = fs.path.join(flutterProject.dartTool.path, 'build', 'entrypoint', 'build.dart');
    if (fs.file(resultScriptPath).existsSync()) {
      return;
    }
    final Status status = logger.startProgress('generating build script...', timeout: null);
    try {
      fs.directory(generatedDirectory).createSync(recursive: true);

      final File syntheticPubspec = fs.file(fs.path.join(generatedDirectory, 'pubspec.yaml'));
      final StringBuffer stringBuffer = StringBuffer();

      stringBuffer.writeln('name: synthetic_example');
      stringBuffer.writeln('dependencies:');
      for (String builder in await flutterProject.builders) {
        stringBuffer.writeln('  $builder: any');
      }
      stringBuffer.writeln('  build_runner: any');
      stringBuffer.writeln('  flutter_build:');
      stringBuffer.writeln('    sdk: flutter');
      await syntheticPubspec.writeAsString(stringBuffer.toString());

      await pubGet(
        context: PubContext.pubGet,
        directory: generatedDirectory,
        upgrade: false,
        checkLastModified: false,
      );
      final PackageGraph packageGraph = PackageGraph.forPath(syntheticPubspec.parent.path);
      final BuildScriptGenerator buildScriptGenerator = buildScriptGeneratorFactory.create(flutterProject, packageGraph);
      await buildScriptGenerator.generateBuildScript();
    } finally {
      status.stop();
    }
  }
}

class BuildResult {
  const BuildResult(this.packagesFile, this.dillFile);

  final File packagesFile;
  final File dillFile;
}
