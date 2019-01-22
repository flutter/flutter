// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:meta/meta.dart';
import '../artifacts.dart';
import '../base/process_manager.dart';
import '../compile.dart';
import '../globals.dart';

const String _kFlutterKernelModuleExtension = '.flutter.dill';
const String _kFlutterModuleExtension = '.flutter.module';

/// A builder which creates a kernel file for a flutter app from dart
/// modules and an entrypoint.
///
/// Unlike the package:build kernel builders, this creates a single kernel from
/// dart source using the frontend server binary.
class FlutterKernelBuilder implements Builder {
  const FlutterKernelBuilder({
    @required this.disabled,
    @required this.target,
    @required this.aot,
    @required this.trackWidgetCreation,
    @required this.targetProductVm,
    @required this.linkPlatformKernelIn,
    @required this.extraFrontEndOptions,
    @required this.sdkRoot,
    @required this.packagesPath,
    this.incrementalCompilerByteStorePath,
    this.fileSystemRoots,
  });

  final String target;
  final String packagesPath;
  final String sdkRoot;
  final String incrementalCompilerByteStorePath;
  final bool aot;
  final bool disabled;
  final bool trackWidgetCreation;
  final bool targetProductVm;
  final bool linkPlatformKernelIn;
  final List<String> extraFrontEndOptions;
  final List<String> fileSystemRoots;

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>['.app.dill'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (disabled) {
      return;
    }
    if (!buildStep.inputId.path.contains('main.dart')) {
      return;
    }
    final AssetId moduleId = buildStep.inputId.changeExtension(_kFlutterModuleExtension);
    final Module module = Module.fromJson(json.decode(await buildStep.readAsString(moduleId)));
    final AssetId outputId = module.primarySource.changeExtension('.app.dill');
    final File outputFile = scratchSpace.fileFor(outputId);
    // I am unsure if this is actually necessary for anything.
    final List<Module> transitiveDeps = await module.computeTransitiveDependencies(buildStep);
    final List<AssetId> transitiveKernelDeps = <AssetId>[];
    final List<AssetId> transitiveSourceDeps = <AssetId>[];
    for (Module dependency in transitiveDeps) {
      await _addModuleDeps(
        dependency,
        module,
        transitiveKernelDeps,
        transitiveSourceDeps,
        buildStep,
        _kFlutterKernelModuleExtension);
    }
    final Set<AssetId> allAssetIds = Set<AssetId>()
      ..addAll(module.sources)
      ..addAll(transitiveKernelDeps)
      ..addAll(transitiveSourceDeps);
    await scratchSpace.ensureAssets(allAssetIds, buildStep);
    final Directory projectDir = File(packagesPath).parent;
    final String oldPackagesFile = await File(packagesPath).readAsString();
    final String newPackagesFile = oldPackagesFile.replaceFirst('hello_world:lib/', 'hello_world:$multiRootScheme:///lib/');
    final Directory packagesFileDir = await Directory.systemTemp.createTemp('flutter_build_');
    final File packagesFile = File(path.join(packagesFileDir.path, '.packages'));
    await packagesFile.create();
    await packagesFile.writeAsString(newPackagesFile);
    // End questionable logic.

    final String frontendServer = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    final String engineDartPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final List<String> command = <String>[
      engineDartPath,
      frontendServer,
      '--sdk-root',
      sdkRoot,
      '--strong',
      '--target=flutter',
    ];
    if (trackWidgetCreation) {
      command.add('--track-widget-creation');
    }
    if (!linkPlatformKernelIn) {
      command.add('--no-link-platform');
    }
    if (aot) {
      command.add('--aot');
      command.add('--tfa');
    }
    if (targetProductVm) {
      command.add('-Ddart.vm.product=true');
    }
    if (incrementalCompilerByteStorePath != null) {
      command.add('--incremental');
    }
    command.addAll(<String>['--packages', packagesFile.path]);
    final Uri mainUri = PackageUriMapper.findUri(target, packagesFile.path, multiRootScheme, fileSystemRoots);
    command.addAll(<String>['--output-dill', outputFile.path]);
    for (String root in <String>[
      path.join(projectDir.absolute.path),
      path.join(projectDir.absolute.path, '.dart_tool', 'build', 'generated', 'hello_world'),
    ]) {
      printTrace('Adding root: $root');
      command.addAll(<String>['--filesystem-root', root]);
    }
    command.addAll(<String>['--filesystem-scheme', multiRootScheme]);
    if (extraFrontEndOptions != null) {
      command.addAll(extraFrontEndOptions);
    }
    command.add(mainUri?.toString() ?? target);

    printTrace(command.join(' '));
    final Process server = await processManager
        .start(command)
        .catchError((dynamic error, StackTrace stack) {
      printError('Failed to start frontend server $error, $stack');
    });

    final StdoutHandler _stdoutHandler = StdoutHandler();
    server.stderr
      .transform<String>(utf8.decoder)
      .listen(printError);
    server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(_stdoutHandler.handler);
    await server.exitCode;
    await _stdoutHandler.compilerOutput.future;
    await scratchSpace.copyOutput(outputId, buildStep);
  }
}

/// A build for incremental runs which only generates a timestamp.
///
/// Forces code generation to run, but allows us to continue delegating
/// to the frontend server to produce incremental dill files.
class FlutterIncrementalKernelBuilder implements Builder {
  const FlutterIncrementalKernelBuilder({
    this.disabled,
  });

  final bool disabled;

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>['.app.incremental.dill.timestamp', '.packages'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (disabled) {
      return;
    }
    if (!buildStep.inputId.path.contains('main.dart')) {
      return;
    }
    final AssetId moduleId = buildStep.inputId.changeExtension(_kFlutterModuleExtension);
    final Module module = Module.fromJson(json.decode(await buildStep.readAsString(moduleId)));
    final AssetId outputId = module.primarySource.changeExtension('.app.incremental.dill.timestamp');
    final AssetId packagesId = module.primarySource.changeExtension('.packages');
    final List<Module> transitiveDeps = await module.computeTransitiveDependencies(buildStep);
    final String package = buildStep.inputId.package;
    final List<AssetId> transitiveKernelDeps = <AssetId>[];
    final List<AssetId> transitiveSourceDeps = <AssetId>[];
    for (Module dependency in transitiveDeps) {
      await _addModuleDeps(
        dependency,
        module,
        transitiveKernelDeps,
        transitiveSourceDeps,
        buildStep,
        _kFlutterKernelModuleExtension,
      );
    }
    final Set<AssetId> allAssetIds = Set<AssetId>()
      ..addAll(module.sources)
      ..addAll(transitiveKernelDeps)
      ..addAll(transitiveSourceDeps);
    await scratchSpace.ensureAssets(allAssetIds, buildStep);
    // Replace the relative root of the current package in the .packages file with a multiroot-scheme
    // so that the compiler can resolve both source files and generated files.
    final String oldPackagesFile = await File('.packages').readAsString();
    oldPackagesFile.replaceFirst('$package:lib/', '$package:$multiRootScheme///lib');
    final String newPackagesFile = oldPackagesFile.replaceFirst('$package:lib/', '$package:$multiRootScheme:///lib/');
    await buildStep.writeAsString(packagesId, newPackagesFile);
    await buildStep.writeAsString(outputId, DateTime.now().toIso8601String());
  }
}

Future<void> _addModuleDeps(
    Module dependency,
    Module root,
    List<AssetId> transitiveKernelDeps,
    List<AssetId> transitiveSourceDeps,
    BuildStep buildStep,
    String outputExtension,
  ) async {
  final AssetId kernelId = dependency.primarySource.changeExtension(outputExtension);
  if (await buildStep.canRead(kernelId)) {
    // If we can read the kernel file, but it depends on any module in this
    // package, then we need to only provide sources for that file since its
    // dependencies in this package will only be providing sources as well.
    if ((await dependency.computeTransitiveDependencies(buildStep))
      .any((Module module) => module.primarySource.package == root.primarySource.package)) {
      transitiveSourceDeps.addAll(dependency.sources);
    } else {
      transitiveKernelDeps.add(kernelId);
    }
  } else {
    transitiveSourceDeps.addAll(dependency.sources);
  }
}

class FlutterTestEntrypointBuilder implements Builder {
  const FlutterTestEntrypointBuilder({
    this.disabled,
  });

  final bool disabled;

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>['.test.timestamp'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (disabled) {
      return;
    }
    final AssetId dartEntrypointId = buildStep.inputId;
    final bool isAppEntrypoint = await _isAppEntryPoint(dartEntrypointId, buildStep);
    if (!isAppEntrypoint) {
      return;
    }
    final AssetId moduleId = buildStep.inputId.changeExtension(moduleExtension(DartPlatform.flutter));
    final AssetId outputId = buildStep.inputId.changeExtension('.test.timestamp');
    final Module module = Module.fromJson(json.decode(await buildStep.readAsString(moduleId)));
    await module.computeTransitiveDependencies(buildStep);
    await buildStep.writeAsString(outputId, DateTime.now().toIso8601String());
  }
}

/// Returns whether or not [dartId] is an app entrypoint (basically, whether
/// or not it has a `main` function).
Future<bool> _isAppEntryPoint(AssetId dartId, AssetReader reader) async {
  final String source = await reader.readAsString(dartId);
  final CompilationUnit parsed = parseCompilationUnit(source, suppressErrors: true);
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  return parsed.declarations.any((CompilationUnitMember node) {
    return node is FunctionDeclaration &&
        node.name.name == 'main' &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}


class TestSvgBuilder implements Builder {
  const TestSvgBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.svg': <String>['.svg.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final AssetId outputId = buildStep.inputId.changeExtension('.svg.dart');
    final String svgSource = await buildStep.readAsString(buildStep.inputId);
    await buildStep.writeAsString(outputId, '''
import 'package:flutter/widgets.dart';

/**
$svgSource
**/
class SvgPainter extends StatelessWidget {
  const SvgPainter({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }
}
