// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'artifacts.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';
import 'compile.dart';
import 'globals.dart';
import 'project.dart';

const String _kMultiRootScheme = 'org-dartlang-app';

/// The [CodeGenerator] instance.
///
/// If [experimentalBuildEnabled] is false, this will contain an unsupported
/// implementation.
CodeGenerator get codeGenerator => context[CodeGenerator];

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

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
abstract class CodeGenerator {
  const CodeGenerator();

  /// Run a partial build include code generators but not kernel.
  Future<void> generate({@required String mainPath}) async {
    await build(
      mainPath: mainPath,
      aot: false,
      linkPlatformKernelIn: false,
      trackWidgetCreation: false,
      targetProductVm: false,
      disableKernelGeneration: true,
    );
  }

  /// Run a full build and return the resulting .packages and dill file.
  ///
  /// The defines of the build command are the arguments required in the
  /// flutter_build kernel builder.
  Future<CodeGenerationResult> build({
    @required String mainPath,
    @required bool aot,
    @required bool linkPlatformKernelIn,
    @required bool trackWidgetCreation,
    @required bool targetProductVm,
    List<String> extraFrontEndOptions = const <String>[],
    bool disableKernelGeneration = false,
  });

  /// Starts a persistent code generting daemon.
  ///
  /// The defines of the daemon command are the arguments required in the
  /// flutter_build kernel builder.
  Future<CodegenDaemon> daemon({
    @required String mainPath,
    bool linkPlatformKernelIn = false,
    bool targetProductVm = false,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions = const <String>[],
  });

  /// Invalidates a generated build script by deleting it.
  ///
  /// Must be called any time a pubspec file update triggers a corresponding change
  /// in .packages.
  Future<void> invalidateBuildScript();

  // Generates a synthetic package under .dart_tool/flutter_tool which is in turn
  // used to generate a build script.
  Future<void> generateBuildScript();
}

class UnsupportedCodeGenerator extends CodeGenerator {
  const UnsupportedCodeGenerator();

  @override
  Future<CodeGenerationResult> build({
    String mainPath,
    bool aot,
    bool linkPlatformKernelIn,
    bool trackWidgetCreation,
    bool targetProductVm,
    List<String> extraFrontEndOptions = const <String> [],
    bool disableKernelGeneration = false,
  }) {
    throw UnsupportedError('build_runner is not currently supported.');
  }

  @override
  Future<void> generateBuildScript() {
    throw UnsupportedError('build_runner is not currently supported.');
  }

  @override
  Future<void> invalidateBuildScript() {
    throw UnsupportedError('build_runner is not currently supported.');
  }

  @override
  Future<CodegenDaemon> daemon({
    String mainPath,
    bool linkPlatformKernelIn = false,
    bool targetProductVm = false,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions = const <String> [],
  }) {
    throw UnsupportedError('build_runner is not currently supported.');
  }
}

abstract class CodegenDaemon {
  /// Whether the previously enqueued build was successful.
  Stream<CodegenStatus> get buildResults;

  /// Starts a new build.
  void startBuild();

  File get packagesFile;

  File get dillFile;
}

/// The result of running a build through a [CodeGenerator].
///
/// If no dill or packages file is generated, they will be null.
class CodeGenerationResult {
  const CodeGenerationResult(this.packagesFile, this.dillFile);

  final File packagesFile;
  final File dillFile;
}

/// An implementation of the [KernelCompiler] which delegates to build_runner.
///
/// Only a subset of the arguments provided to the [KernelCompiler] are
/// supported here. Using the build pipeline implies a fixed multiroot
/// filesystem and requires a pubspec.
///
/// This is only safe to use if [experimentalBuildEnabled] is true.
class CodeGeneratingKernelCompiler implements KernelCompiler {
  const CodeGeneratingKernelCompiler();

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
    try {
      final CodeGenerationResult buildResult = await codeGenerator.build(
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

/// An implementation of a [ResidentCompiler] which runs a [BuildRunner] before
/// talking to the CFE.
class CodeGeneratingResidentCompiler implements ResidentCompiler {
  CodeGeneratingResidentCompiler._(this._residentCompiler, this._codegenDaemon);

  /// Creates a new [ResidentCompiler] and configures a [BuildDaemonClient] to
  /// run builds.
  static Future<CodeGeneratingResidentCompiler> create({
    @required String mainPath,
    bool trackWidgetCreation = false,
    CompilerMessageConsumer compilerMessageConsumer = printError,
    bool unsafePackageSerialization = false,
  }) async {
    final FlutterProject flutterProject = await FlutterProject.current();
    final CodegenDaemon codegenDaemon = await codeGenerator.daemon(
      extraFrontEndOptions: <String>[],
      linkPlatformKernelIn: false,
      mainPath: mainPath,
      targetProductVm: false,
      trackWidgetCreation: trackWidgetCreation,
    );
    codegenDaemon.startBuild();
    final CodegenStatus status = await codegenDaemon.buildResults.firstWhere((CodegenStatus status) {
      return status ==CodegenStatus.Succeeded || status == CodegenStatus.Failed;
    });
    if (status == CodegenStatus.Failed) {
      printError('Codegeneration failed, halting build.');
    }
    final ResidentCompiler residentCompiler = ResidentCompiler(
      artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
      trackWidgetCreation: trackWidgetCreation,
      packagesPath: codegenDaemon.packagesFile.path,
      fileSystemRoots: <String>[
        fs.path.join(flutterProject.generated.absolute.path, 'lib${platform.pathSeparator}'),
        fs.path.join(flutterProject.directory.path, 'lib${platform.pathSeparator}'),
      ],
      fileSystemScheme: _kMultiRootScheme,
      targetModel: TargetModel.flutter,
      unsafePackageSerialization: unsafePackageSerialization,
    );
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
  Future<CompilerOutput> recompile(String mainPath, List<String> invalidatedFiles, {String outputPath, String packagesFilePath}) async {
    _codegenDaemon.startBuild();
    final CodegenStatus status = await _codegenDaemon.buildResults.firstWhere((CodegenStatus status) {
      return status ==CodegenStatus.Succeeded || status == CodegenStatus.Failed;
    });
    if (status == CodegenStatus.Failed) {
      printError('Codegeneration failed, halting build.');
    }
    // Delete this file so that the frontend_server can handle multi-root.
    // TODO(jonahwilliams): investigate frontend_server behavior in the presence
    // of multi-root and initialize from dill.
    if (await fs.file(outputPath).exists()) {
      await fs.file(outputPath).delete();
    }
    return _residentCompiler.recompile(
      mainPath,
      invalidatedFiles,
      outputPath: outputPath,
      packagesFilePath: _codegenDaemon.packagesFile.path,
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
