// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
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
  return true;
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
    final Process buildProcess = await processManager.start(<String>[
      dartPath,
      '--packages=$scriptPackagesPath',
      buildScript,
      'build',
      '--define', 'flutter_build|kernel=disabled=true',
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
    status.stop();
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
    if (!await buildScript.exists()) {
      return;
    }
    await buildScript.delete();
  }

  /// Generates a build script.
  Future<void> generateBuildScript() async {
    final FlutterProject flutterProject = await FlutterProject.current();
    final Directory generatedDirectory = flutterProject.dartTool
      .absolute
      .childDirectory('flutter_tool');
    if (await flutterProject
        .dartTool
        .childDirectory('build')
        .childDirectory('entrypoint')
        .childFile('build.dart').exists()) {
      return;
    }
    final Status status = logger.startProgress('generating build script...', timeout: null);
    await generatedDirectory.create(recursive: true);

    final Map<String, Uri> packages = PackageMap(flutterProject.packagesFile.path).map;
    final File syntheticPubspec = fs.file(fs.path.join(generatedDirectory.path, 'pubspec.yaml'));
    final StringBuffer stringBuffer = StringBuffer();
    // Give generated pubspec the same name to trick build_runner into thinking
    // that it is the root package.
    stringBuffer.writeln('name: ${flutterProject.manifest.appName}');
    stringBuffer.writeln('dependencies:');
    bool hasBuildRunnerDependency = false;
    // Skip packages dependencies which refer to the flutter SDK.
    const List<String> flutterPackages = <String>[
      'flutter',
      'flutter_test',
      'flutter_driver',
      'flutter_localizations',
    ];
    const List<String> dontInclude = <String>[
      'sky_engine',
      'sky_services',
    ];
    for (String packageName in packages.keys) {
      if (packageName == 'build_runner') {
        hasBuildRunnerDependency = true;
      }
      if (packageName == flutterProject.manifest.appName || dontInclude.contains(packageName)) {
        continue;
      } else if (flutterPackages.contains(packageName)) {
        stringBuffer.writeln('  $packageName:');
        stringBuffer.writeln('    sdk: flutter');
      } else {
        stringBuffer.writeln('  $packageName: any');
      }
    }
    if (!hasBuildRunnerDependency) {
      stringBuffer.writeln('  build_runner: any');
    }
    final String flutterToolsLocation = fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools');
    stringBuffer.writeln('  flutter_tools:');
    stringBuffer.writeln('    path: $flutterToolsLocation');

    await syntheticPubspec.writeAsString(stringBuffer.toString());
    await pubGet(
      context: PubContext.pubUpgrade,
      directory: generatedDirectory.path,
      upgrade: true,
      checkLastModified: false,
    );

    final String pubExecutable = fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk','bin', 'pub');
    await processManager.run(<String>[
      pubExecutable,
      'run',
      'build_runner',
      'generate-build-script',
    ], workingDirectory: generatedDirectory.path);

    final File generatedBuildSnapshot = generatedDirectory
      .childDirectory('.dart_tool')
      .childDirectory('build')
      .childDirectory('entrypoint')
      .childFile('build.dart');
    if (!await generatedBuildSnapshot.exists()) {
      throwToolExit('Failed to generate build script');
    }
    final File result = await flutterProject
      .dartTool
      .childDirectory('build')
      .childDirectory('entrypoint')
      .childFile('build.dart').create(recursive: true);
    final String buildScriptSource = await generatedBuildSnapshot.readAsString();
    final String modifiedBuildScriptSource = _updateBuildScript(buildScriptSource);
    await result.writeAsString(modifiedBuildScriptSource);
    status.stop();
  }

  String _updateBuildScript(String source) {
    const String imports = r'''
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner/src/entrypoint/build.dart';
import 'package:build_runner/src/entrypoint/clean.dart';
import 'package:build_runner/src/entrypoint/daemon.dart';
import 'package:build_runner/src/entrypoint/serve.dart';
import 'package:build_runner/src/entrypoint/test.dart';
import 'package:build_runner/src/entrypoint/watch.dart';
import 'package:build_runner/src/entrypoint/runner.dart';
''';
    const String body = r'''
void main(List<String> args, [_i5.SendPort sendPort]) async {
  var runner = FlutterBuildCommandRunner(_builders);
  var result = 0;
  try {
    result = await runner.run(args);
  } catch (err) {
    print(err);
    result = 1;
  }
  sendPort?.send(result);
}

class FlutterBuildCommandRunner extends CommandRunner<int> implements BuildCommandRunner {
  final List<BuilderApplication> builderApplications;

  PackageGraph get packageGraph => _packageGraph;
  PackageGraph _packageGraph;

  FlutterBuildCommandRunner(List<BuilderApplication> builderApplications)
      : builderApplications = List.unmodifiable(builderApplications),
        super('build_runner', 'Unified interface for running Dart builds.') {
       final packageGraph  = PackageGraph.forPath(path.join('.dart_tool', 'flutter_tool'));
       final PackageNode rootNode = packageGraph.root;
       final PackageNode newRootNode = PackageNode(
         rootNode.name,
         path.current,
         rootNode.dependencyType,
         isRoot: true,
       );
       newRootNode.dependencies.addAll(rootNode.dependencies);
       _packageGraph = PackageGraph.fromRoot(newRootNode);
    addCommand(DaemonCommand());
    addCommand(BuildCommand());
    addCommand(WatchCommand());
    addCommand(ServeCommand());
    addCommand(TestCommand(packageGraph));
    addCommand(CleanCommand());
  }

  String get usageWithoutDescription => '';
}
''';
    const String mainPattern = r'main(List<String> args';
    final StringBuffer buffer = StringBuffer();
    buffer.write(imports);
    buffer.write(source.split(mainPattern).first);
    buffer.write(body);
    return buffer.toString();
  }
}

class BuildResult {
  const BuildResult(this.packagesFile, this.dillFile);

  final File packagesFile;
  final File dillFile;
}
