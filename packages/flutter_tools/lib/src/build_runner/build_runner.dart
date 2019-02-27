// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_runner_core/build_runner_core.dart' hide BuildStatus;
import 'package:build_daemon/data/server_log.dart';
import 'package:build_daemon/data/build_status.dart' as build;
import 'package:build_daemon/client.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process_manager.dart';
import '../cache.dart';
import '../codegen.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../project.dart';
import '../resident_runner.dart';
import 'build_script_generator.dart';

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
class BuildRunner extends CodeGenerator {
  const BuildRunner();

  @override
  Future<CodeGenerationResult> build({
    @required String mainPath,
    @required bool aot,
    @required bool linkPlatformKernelIn,
    @required bool trackWidgetCreation,
    @required bool targetProductVm,
    List<String> extraFrontEndOptions = const <String>[],
    bool disableKernelGeneration = false,
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
        '--skip-build-script-check',
        '--define', 'flutter_build|kernel=disabled=$disableKernelGeneration',
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
          .listen(printTrace);
      buildProcess
          .stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(printError);
      await buildProcess.exitCode;
    } finally {
      status.stop();
    }
    if (disableKernelGeneration) {
      return const CodeGenerationResult(null, null);
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
    return CodeGenerationResult(packagesFile, dillFile);
  }

  @override
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

  @override
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

      stringBuffer.writeln('name: flutter_tool');
      stringBuffer.writeln('dependencies:');
      final YamlMap builders = await flutterProject.builders;
      if (builders != null) {
        for (String name in builders.keys) {
          final YamlNode node = builders[name];
          stringBuffer.writeln('  $name: $node');
        }
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
      final BuildScriptGenerator buildScriptGenerator = const BuildScriptGeneratorFactory().create(flutterProject, packageGraph);
      await buildScriptGenerator.generateBuildScript();
    } finally {
      status.stop();
    }
  }

  @override
  Future<CodegenDaemon> daemon({
    String mainPath,
    bool linkPlatformKernelIn = false,
    bool targetProductVm = false,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions = const <String> [],
  }) async {
    mainPath ??= findMainDartFile();
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
    final Status status = logger.startProgress('starting build daemon...', timeout: null);
    BuildDaemonClient buildDaemonClient;
    try {
      final List<String> command = <String>[
        dartPath,
        '--packages=$scriptPackagesPath',
        buildScript,
        'daemon',
         '--skip-build-script-check',
        '--define', 'flutter_build|kernel=disabled=false',
        '--define', 'flutter_build|kernel=aot=false',
        '--define', 'flutter_build|kernel=linkPlatformKernelIn=$linkPlatformKernelIn',
        '--define', 'flutter_build|kernel=trackWidgetCreation=$trackWidgetCreation',
        '--define', 'flutter_build|kernel=targetProductVm=$targetProductVm',
        '--define', 'flutter_build|kernel=mainPath=$mainPath',
        '--define', 'flutter_build|kernel=packagesPath=$packagesPath',
        '--define', 'flutter_build|kernel=sdkRoot=$sdkRoot',
        '--define', 'flutter_build|kernel=frontendServerPath=$frontendServerPath',
        '--define', 'flutter_build|kernel=engineDartBinaryPath=$engineDartBinaryPath',
        '--define', 'flutter_build|kernel=extraFrontEndOptions=${extraFrontEndOptions ?? const <String>[]}',
      ];
      buildDaemonClient = await BuildDaemonClient.connect(flutterProject.directory.path, command, logHandler: (ServerLog log) => printTrace(log.toString()));
    } finally {
      status.stop();
    }
    buildDaemonClient.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder builder) {
      builder.target = flutterProject.manifest.appName;
    }));
    final String relativeMain = fs.path.relative(mainPath, from: flutterProject.directory.path);
    final File generatedPackagesFile = fs.file(fs.path.join(flutterProject.generated.path, fs.path.setExtension(relativeMain, '.packages')));
    final File generatedDillFile = fs.file(fs.path.join(flutterProject.generated.path, fs.path.setExtension(relativeMain, '.app.dill')));
    return _BuildRunnerCodegenDaemon(buildDaemonClient, generatedPackagesFile, generatedDillFile);
  }
}

class _BuildRunnerCodegenDaemon implements CodegenDaemon {
  _BuildRunnerCodegenDaemon(this.buildDaemonClient, this.packagesFile, this.dillFile);

  final BuildDaemonClient buildDaemonClient;
  @override
  final File packagesFile;
  @override
  final File dillFile;
  @override
  CodegenStatus get lastStatus => _lastStatus;
  CodegenStatus _lastStatus;

  @override
  Stream<CodegenStatus> get buildResults => buildDaemonClient.buildResults.map((build.BuildResults results) {
    if (results.results.first.status == BuildStatus.failed) {
      return _lastStatus = CodegenStatus.Failed;
    }
    if (results.results.first.status == BuildStatus.started) {
      return _lastStatus = CodegenStatus.Started;
    }
    if (results.results.first.status == BuildStatus.succeeded) {
      return _lastStatus = CodegenStatus.Succeeded;
    }
    _lastStatus = null;
    return null;
  });

  @override
  void startBuild() {
    buildDaemonClient.startBuild();
  }
}
