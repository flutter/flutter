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
import 'package:yaml/yaml.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../codegen.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../project.dart';
import 'build_script_generator.dart';

/// The minimum version of build_runner we can support in the flutter tool
const String kMinimumBuildRunnerVersion = '1.2.8';

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
class BuildRunner extends CodeGenerator {
  const BuildRunner();

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
      stringBuffer.writeln('  build_runner: ^$kMinimumBuildRunnerVersion');
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
  Future<CodegenDaemon> daemon() async {
    await generateBuildScript();
    final FlutterProject flutterProject = await FlutterProject.current();
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
      ];
      buildDaemonClient = await BuildDaemonClient.connect(flutterProject.directory.path, command, logHandler: (ServerLog log) => printTrace(log.toString()));
    } finally {
      status.stop();
    }
    buildDaemonClient.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder builder) {
      builder.target = flutterProject.manifest.appName;
    }));
    return _BuildRunnerCodegenDaemon(buildDaemonClient);
  }
}

class _BuildRunnerCodegenDaemon implements CodegenDaemon {
  _BuildRunnerCodegenDaemon(this.buildDaemonClient);

  final BuildDaemonClient buildDaemonClient;

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
