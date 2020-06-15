// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';

import 'base/context.dart';
import 'build_info.dart';
import 'compile.dart';
import 'globals.dart' as globals;
import 'project.dart';

/// The [CodeGenerator] instance.
///
/// If [experimentalBuildEnabled] is false, this will contain an unsupported
/// implementation.
CodeGenerator get codeGenerator => context.get<CodeGenerator>();

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
abstract class CodeGenerator {
  const CodeGenerator();

  /// Starts a persistent code generating daemon.
  ///
  /// The defines of the daemon command are the arguments required in the
  /// flutter_build kernel builder.
  Future<CodegenDaemon> daemon(FlutterProject flutterProject);

  // Generates a synthetic package under .dart_tool/flutter_tool which is in turn
  // used to generate a build script.
  Future<void> generateBuildScript(FlutterProject flutterProject);
}

class UnsupportedCodeGenerator extends CodeGenerator {
  const UnsupportedCodeGenerator();

  @override
  Future<void> generateBuildScript(FlutterProject flutterProject) {
    throw UnsupportedError('build_runner is not currently supported.');
  }

  @override
  Future<CodegenDaemon> daemon(FlutterProject flutterProject) {
    throw UnsupportedError('build_runner is not currently supported.');
  }
}

abstract class CodegenDaemon {
  /// Whether the previously enqueued build was successful.
  Stream<CodegenStatus> get buildResults;

  CodegenStatus get lastStatus;

  /// Starts a new build.
  void startBuild();
}

/// An implementation of the [KernelCompiler] which delegates to build_runner.
///
/// Only a subset of the arguments provided to the [KernelCompiler] are
/// supported here. Using the build pipeline implies a fixed multi-root
/// filesystem and requires a pubspec.
class CodeGeneratingKernelCompiler implements KernelCompiler {
  const CodeGeneratingKernelCompiler();

  static const KernelCompiler _delegate = KernelCompiler();

  @override
  Future<CompilerOutput> compile({
    String mainPath,
    String outputFilePath,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    String sdkRoot,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
    String initializeFromDill,
    String platformDill,
    List<String> dartDefines,
    @required BuildMode buildMode,
    @required PackageConfig packageConfig,
  }) async {
    final FlutterProject flutterProject = FlutterProject.current();
    final CodegenDaemon codegenDaemon = await codeGenerator.daemon(flutterProject);
    codegenDaemon.startBuild();
    await for (final CodegenStatus codegenStatus in codegenDaemon.buildResults) {
      if (codegenStatus == CodegenStatus.Failed) {
        globals.printError('Code generation failed, build may have compile errors.');
        break;
      }
      if (codegenStatus == CodegenStatus.Succeeded) {
        break;
      }
    }
    return _delegate.compile(
      mainPath: mainPath,
      outputFilePath: outputFilePath,
      linkPlatformKernelIn: linkPlatformKernelIn,
      aot: aot,
      buildMode: buildMode,
      trackWidgetCreation: trackWidgetCreation,
      extraFrontEndOptions: extraFrontEndOptions,
      sdkRoot: sdkRoot,
      packagesPath: packagesPath,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      depFilePath: depFilePath,
      targetModel: targetModel,
      initializeFromDill: initializeFromDill,
      dartDefines: dartDefines,
      packageConfig: packageConfig,
    );
  }
}

/// An implementation of a [ResidentCompiler] which runs a [BuildRunner] before
/// talking to the CFE.
class CodeGeneratingResidentCompiler implements ResidentCompiler {
  CodeGeneratingResidentCompiler._(this._residentCompiler, this._codegenDaemon);

  /// Creates a new [ResidentCompiler] and configures a [BuildDaemonClient] to
  /// run builds.
  ///
  /// If `runCold` is true, then no codegen daemon will be created. Instead the
  /// compiler will only be initialized with the correct configuration for
  /// codegen mode.
  static Future<ResidentCompiler> create({
    @required ResidentCompiler residentCompiler,
    @required FlutterProject flutterProject,
    bool runCold = false,
  }) async {
    if (runCold) {
      return residentCompiler;
    }
    globals.printError(<String>[
      '"flutter generate" is deprecated, use "dart pub run build_runner" instead. ',
      'The following dependencies must be added to dev_dependencies in pubspec.yaml:',
      'build_runner: 1.10.0',
      for (Object dependency in flutterProject.builders?.keys ?? const <Object>[])
        '$dependency: ${flutterProject.builders[dependency]}'
    ].join('\n'));

    final CodegenDaemon codegenDaemon = await codeGenerator.daemon(flutterProject);
    codegenDaemon.startBuild();
    final CodegenStatus status = await codegenDaemon.buildResults.firstWhere((CodegenStatus status) {
      return status == CodegenStatus.Succeeded || status == CodegenStatus.Failed;
    });
    if (status == CodegenStatus.Failed) {
      globals.printError('Code generation failed, build may have compile errors.');
    }
    return CodeGeneratingResidentCompiler._(residentCompiler, codegenDaemon);
  }

  final ResidentCompiler _residentCompiler;
  final CodegenDaemon _codegenDaemon;

  @override
  void accept() {
    _residentCompiler.accept();
  }

  @override
  Future<CompilerOutput> compileExpression(String expression, List<String> definitions, List<String> typeDefinitions, String libraryUri, String klass, bool isStatic) {
    return _residentCompiler.compileExpression(expression, definitions, typeDefinitions, libraryUri, klass, isStatic);
  }

  @override
  Future<CompilerOutput> compileExpressionToJs(
    String libraryUri, int line, int column, Map<String, String> jsModules,
    Map<String, String> jsFrameValues, String moduleName, String expression
  ) {
    return _residentCompiler.compileExpressionToJs(
      libraryUri, line, column, jsModules, jsFrameValues, moduleName, expression);
  }

  @override
  Future<CompilerOutput> recompile(
    Uri mainUri,
    List<Uri> invalidatedFiles, {
      String outputPath,
      PackageConfig packageConfig,
      bool suppressErrors = false,
    }) async {
    if (_codegenDaemon.lastStatus != CodegenStatus.Succeeded && _codegenDaemon.lastStatus != CodegenStatus.Failed) {
      await _codegenDaemon.buildResults.firstWhere((CodegenStatus status) {
        return status == CodegenStatus.Succeeded || status == CodegenStatus.Failed;
      });
    }
    if (_codegenDaemon.lastStatus == CodegenStatus.Failed) {
      globals.printError('Code generation failed, build may have compile errors.');
    }
    return _residentCompiler.recompile(
      mainUri,
      invalidatedFiles,
      outputPath: outputPath,
      packageConfig: packageConfig,
      suppressErrors: suppressErrors,
    );
  }

  @override
  Future<CompilerOutput> reject() {
    return _residentCompiler.reject();
  }

  @override
  void reset() {
    _residentCompiler.reset();
  }

  @override
  Future<void> shutdown() {
    return _residentCompiler.shutdown();
  }

  @override
  void addFileSystemRoot(String root) {
    _residentCompiler.addFileSystemRoot(root);
  }
}

/// The current status of a codegen build.
enum CodegenStatus {
  /// The build has started running.
  ///
  /// If this is the current status when running a hot reload, an additional build does
  /// not need to be started.
  Started,
  /// The build succeeded.
  Succeeded,
  /// The build failed.
  Failed
}
