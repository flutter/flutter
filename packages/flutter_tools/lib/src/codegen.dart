// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'artifacts.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'globals.dart';
import 'project.dart';

// Arbitrarily chosen multi-root file scheme. This is used to configure the
// frontend_server to resolve a package uri to multiple filesystem directories.
// In this case, the source directory and a generated directory.
const String kMultiRootScheme = 'org-dartlang-app';

/// The [CodeGenerator] instance.
///
/// If [experimentalBuildEnabled] is false, this will contain an unsupported
/// implementation.
CodeGenerator get codeGenerator => context.get<CodeGenerator>();

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
abstract class CodeGenerator {
  const CodeGenerator();

  /// Starts a persistent code generting daemon.
  ///
  /// The defines of the daemon command are the arguments required in the
  /// flutter_build kernel builder.
  Future<CodegenDaemon> daemon(FlutterProject flutterProject);

  // Generates a synthetic package under .dart_tool/flutter_tool which is in turn
  // used to generate a build script.
  Future<void> generateBuildScript(FlutterProject flutterProject);

  /// Create generated packages file which adds a multi-root scheme to the user's
  /// project directory. Currently we only replace the root package with a multiroot
  /// scheme. To support codegen on arbitrary packages we would need to do
  /// this for each dependency.
  void updatePackages(FlutterProject flutterProject) {
    final String oldPackagesContents = fs.file(PackageMap.globalPackagesPath).readAsStringSync();
    final String appName = flutterProject.manifest.appName;
    final String newPackagesContents = oldPackagesContents.replaceFirst('$appName:lib/', '$appName:$kMultiRootScheme:/');
    final String generatedPackagesPath = fs.path.setExtension(PackageMap.globalPackagesPath, '.generated');
    fs.file(generatedPackagesPath).writeAsStringSync(newPackagesContents);
  }
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
/// supported here. Using the build pipeline implies a fixed multiroot
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
    bool enableAsserts = false,
    bool causalAsyncStacks = true,
    bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    bool targetProductVm = false,
    // These arguments are currently unused.
    String sdkRoot,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
    String initializeFromDill,
    String platformDill,
  }) async {
    if (fileSystemRoots != null || fileSystemScheme != null || depFilePath != null || targetModel != null || sdkRoot != null || packagesPath != null) {
      printTrace('fileSystemRoots, fileSystemScheme, depFilePath, targetModel,'
        'sdkRoot, packagesPath are not supported when using the experimental '
        'build* pipeline');
    }
    final FlutterProject flutterProject = FlutterProject.current();
    codeGenerator.updatePackages(flutterProject);
    final CodegenDaemon codegenDaemon = await codeGenerator.daemon(flutterProject);
    codegenDaemon.startBuild();
    await for (CodegenStatus codegenStatus in codegenDaemon.buildResults) {
      if (codegenStatus == CodegenStatus.Failed) {
        printError('Code generation failed, build may have compile errors.');
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
      enableAsserts: enableAsserts,
      causalAsyncStacks: causalAsyncStacks,
      trackWidgetCreation: trackWidgetCreation,
      extraFrontEndOptions: extraFrontEndOptions,
      targetProductVm: targetProductVm,
      sdkRoot: sdkRoot,
      packagesPath: PackageMap.globalGeneratedPackagesPath,
      fileSystemRoots: <String>[
        fs.path.join(flutterProject.generated.path, 'lib${platform.pathSeparator}'),
        fs.path.join(flutterProject.directory.path, 'lib${platform.pathSeparator}'),
      ],
      fileSystemScheme: kMultiRootScheme,
      depFilePath: depFilePath,
      targetModel: targetModel,
      initializeFromDill: initializeFromDill,
    );
  }
}

/// An implementation of a [ResidentCompiler] which runs a [BuildRunner] before
/// talking to the CFE.
class CodeGeneratingResidentCompiler implements ResidentCompiler {
  CodeGeneratingResidentCompiler._(this._residentCompiler, this._codegenDaemon, this._flutterProject);

  /// Creates a new [ResidentCompiler] and configures a [BuildDaemonClient] to
  /// run builds.
  ///
  /// If `runCold` is true, then no codegen daemon will be created. Instead the
  /// compiler will only be initialized with the correct configuration for
  /// codegen mode.
  static Future<ResidentCompiler> create({
    @required FlutterProject flutterProject,
    bool enableAsserts = false,
    bool trackWidgetCreation = false,
    CompilerMessageConsumer compilerMessageConsumer = printError,
    bool unsafePackageSerialization = false,
    String outputPath,
    String initializeFromDill,
    bool runCold = false,
  }) async {
    codeGenerator.updatePackages(flutterProject);
    final ResidentCompiler residentCompiler = ResidentCompiler(
      artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
      enableAsserts: enableAsserts,
      trackWidgetCreation: trackWidgetCreation,
      packagesPath: PackageMap.globalGeneratedPackagesPath,
      fileSystemRoots: <String>[
        fs.path.join(flutterProject.generated.path, 'lib${platform.pathSeparator}'),
        fs.path.join(flutterProject.directory.path, 'lib${platform.pathSeparator}'),
      ],
      fileSystemScheme: kMultiRootScheme,
      targetModel: TargetModel.flutter,
      unsafePackageSerialization: unsafePackageSerialization,
      initializeFromDill: initializeFromDill,
    );
    if (runCold) {
      return residentCompiler;
    }
    final CodegenDaemon codegenDaemon = await codeGenerator.daemon(flutterProject);
    codegenDaemon.startBuild();
    final CodegenStatus status = await codegenDaemon.buildResults.firstWhere((CodegenStatus status) {
      return status == CodegenStatus.Succeeded || status == CodegenStatus.Failed;
    });
    if (status == CodegenStatus.Failed) {
      printError('Code generation failed, build may have compile errors.');
    }
    return CodeGeneratingResidentCompiler._(residentCompiler, codegenDaemon, flutterProject);
  }

  final ResidentCompiler _residentCompiler;
  final CodegenDaemon _codegenDaemon;
  final FlutterProject _flutterProject;

  @override
  void accept() {
    _residentCompiler.accept();
  }

  @override
  Future<CompilerOutput> compileExpression(String expression, List<String> definitions, List<String> typeDefinitions, String libraryUri, String klass, bool isStatic) {
    return _residentCompiler.compileExpression(expression, definitions, typeDefinitions, libraryUri, klass, isStatic);
  }

  @override
  Future<CompilerOutput> recompile(String mainPath, List<Uri> invalidatedFiles, {String outputPath, String packagesFilePath}) async {
    if (_codegenDaemon.lastStatus != CodegenStatus.Succeeded && _codegenDaemon.lastStatus != CodegenStatus.Failed) {
      await _codegenDaemon.buildResults.firstWhere((CodegenStatus status) {
        return status == CodegenStatus.Succeeded || status == CodegenStatus.Failed;
      });
    }
    if (_codegenDaemon.lastStatus == CodegenStatus.Failed) {
      printError('Code generation failed, build may have compile errors.');
    }
    // Update the generated packages file if the original packages file has changes.
    if (fs.statSync(PackageMap.globalPackagesPath).modified.millisecondsSinceEpoch >
        fs.statSync(PackageMap.globalGeneratedPackagesPath).modified.millisecondsSinceEpoch) {
      codeGenerator.updatePackages(_flutterProject);
      invalidatedFiles.add(fs.file(PackageMap.globalGeneratedPackagesPath).uri);
    }
    return _residentCompiler.recompile(
      mainPath,
      invalidatedFiles,
      outputPath: outputPath,
      packagesFilePath: PackageMap.globalGeneratedPackagesPath,
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
