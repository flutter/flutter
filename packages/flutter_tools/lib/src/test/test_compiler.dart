// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../compile.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'test_time_recorder.dart';

/// A request to the [TestCompiler] for recompilation.
final class _CompilationRequest {
  _CompilationRequest(this.mainUri);

  /// The entrypoint (containing `main()`) to the Dart program being compiled.
  final Uri mainUri;

  /// Invoked when compilation is completed with the compilation output path.
  Future<TestCompilerResult> get result => _result.future;
  final Completer<TestCompilerResult> _result = Completer<TestCompilerResult>();
}

@immutable
sealed class TestCompilerResult {
  const TestCompilerResult({required this.mainUri});

  final Uri mainUri;
}

final class TestCompilerComplete extends TestCompilerResult {
  const TestCompilerComplete({required this.outputPath, required super.mainUri});

  final String outputPath;

  @override
  bool operator ==(Object other) {
    if (other is! TestCompilerComplete) {
      return false;
    }
    return mainUri == other.mainUri && outputPath == other.outputPath;
  }

  @override
  int get hashCode => Object.hash(mainUri, outputPath);

  @override
  String toString() {
    return 'TestCompilerComplete(mainUri: $mainUri, outputPath: $outputPath)';
  }
}

/// A failed run of [TestCompiler.compile].
final class TestCompilerFailure extends TestCompilerResult {
  const TestCompilerFailure({required this.error, required super.mainUri});

  /// Error message that occurred failing compilation.
  final String error;

  @override
  bool operator ==(Object other) {
    if (other is! TestCompilerFailure) {
      return false;
    }
    return mainUri == other.mainUri && error == other.error;
  }

  @override
  int get hashCode => Object.hash(mainUri, error);

  @override
  String toString() {
    return 'TestCompilerComplete(mainUri: $mainUri, error: $error)';
  }
}

class KernelCacheFile {
  final io.File file;

  bool _created = false;

  KernelCacheFile(this.file);

  String get path => file.path;

  Future<void> maybeUpdateWith(File other) async {
    if (!_created || (file.lengthSync() < other.lengthSync())) {
      // The idea is to keep the cache file up-to-date and include as
      // much as possible in an effort to re-use as many packages as
      // possible.
      if (!_created) {
        file.parent.createSync(recursive: true);
        _created = true;
      }

      globals.printTrace('Copying updated $other to kernel cache: $file');

      await other.copy(file.path);
    }
  }
}

class ActualTestCompiler {
  ResidentCompiler compiler;
  final FlutterProject project;
  final BuildInfo buildInfo;
  final Directory output;
  final KernelCacheFile cacheKernelFile;
  final File outputDill;

  ActualTestCompiler({
    required this.project,
    required this.output,
    required this.buildInfo,
    required this.cacheKernelFile,
  }) : outputDill = output.childFile('output.dill'),
       compiler = _createCompiler(buildInfo, cacheKernelFile) {
    globals.printTrace(
      'Compiler will use the following file as its incremental dill file: ${outputDill.path}',
    );
  }

  Future<TestCompilerResult> compile(Uri mainUri) async {
    final CompilerOutput? compilerOutput = await compiler.recompile(
      mainUri,
      [mainUri, project.dartPluginRegistrant.absolute.uri],
      outputPath: outputDill.path,
      packageConfig: buildInfo.packageConfig,
      projectRootPath: project.directory.absolute.path,
      checkDartPluginRegistry: true,
      fs: globals.fs,
    );

    if (compilerOutput == null || compilerOutput.errorCount > 0) {
      unawaited(compiler.shutdown());
      compiler = _createCompiler(buildInfo, cacheKernelFile);
      return TestCompilerFailure(
        error: compilerOutput!.errorMessage ?? 'Unknown Error',
        mainUri: mainUri,
      );
    } else {
      try {
        final File compilerOutputFile = globals.fs.file(compilerOutput.outputFilename);
        await cacheKernelFile.maybeUpdateWith(compilerOutputFile);

        final String path = mainUri.toFilePath(windows: globals.platform.isWindows);
        final File kernelReadyToRun = await compilerOutputFile.copy('$path.dill');
        return TestCompilerComplete(outputPath: kernelReadyToRun.path, mainUri: mainUri);
      } finally {
        compiler.accept();
        compiler.reset();
      }
    }
  }

  Future<void> shutdown() async {
    await compiler.shutdown();
    globals.printTrace('Deleting ${output.path}...');
    output.deleteSync(recursive: true);
  }
}

ResidentCompiler _createCompiler(BuildInfo bi, KernelCacheFile cacheFile) {
  return ResidentCompiler(
    globals.artifacts!.getArtifactPath(Artifact.flutterPatchedSdkPath),
    artifacts: globals.artifacts!,
    logger: globals.logger,
    processManager: globals.processManager,
    buildMode: bi.mode,
    trackWidgetCreation: bi.trackWidgetCreation,
    initializeFromDill: cacheFile.path,
    dartDefines: bi.dartDefines,
    packagesPath: bi.packageConfigPath,
    frontendServerStarterPath: bi.frontendServerStarterPath,
    extraFrontEndOptions: bi.extraFrontEndOptions,
    platform: globals.platform,
    testCompilation: true,
    fileSystem: globals.fs,
    fileSystemRoots: bi.fileSystemRoots,
    fileSystemScheme: bi.fileSystemScheme,
  );
}

/// A frontend_server wrapper for the flutter test runner.
///
/// This class is a wrapper around compiler that allows multiple isolates to
/// enqueue compilation requests.
class TestCompiler {
  final StreamController<_CompilationRequest> compilerController = StreamController();
  final List<_CompilationRequest> compilationQueue = [];
  final FlutterProject flutterProject;
  final BuildInfo buildInfo;
  final TestTimeRecorder? testTimeRecorder;
  final ActualTestCompiler compiler;

  /// [trackWidgetCreation] configures whether the kernel transform is applied
  /// to the output. This also changes the output file to include a '.track`
  /// extension.
  TestCompiler(this.buildInfo, FlutterProject? flutterProject, {this.testTimeRecorder})
    : flutterProject = flutterProject!,
      compiler = ActualTestCompiler(
        project: flutterProject,
        output: globals.fs.systemTempDirectory.createTempSync('flutter_test_compiler.'),
        buildInfo: buildInfo,
        cacheKernelFile: KernelCacheFile(
          globals.fs.file(
            globals.fs.path.join(
              flutterProject.directory.path,
              getBuildDirectory(),
              'test_cache',
              getDefaultCachedKernelPath(
                trackWidgetCreation: buildInfo.trackWidgetCreation,
                dartDefines: buildInfo.dartDefines,
                extraFrontEndOptions: buildInfo.extraFrontEndOptions,
              ),
            ),
          ),
        ),
      ) {
    // Compiler maintains and updates single incremental dill file.
    // Incremental compilation requests done for each test copy that file away
    // for independent execution.
    globals.printTrace('Listening to compiler controller...');
    compilerController.stream.listen(_onCompilationRequest);
  }

  /// Compiles the Dart program (an entrypoint containing `main()`).
  Future<TestCompilerResult> compile(Uri dartEntrypointPath) {
    if (compilerController.isClosed) {
      throw StateError('TestCompiler is already disposed.');
    }
    final _CompilationRequest request = _CompilationRequest(dartEntrypointPath);
    compilerController.add(request);
    return request.result;
  }

  Future<void> _shutdown() async {
    await compiler.shutdown();
  }

  Future<void> dispose() async {
    await compilerController.close();
    await _shutdown();
  }

  Future<void> _onCompilationRequest(_CompilationRequest request) async {
    final bool isEmpty = compilationQueue.isEmpty;
    compilationQueue.add(request);
    // Only trigger processing if queue was empty - i.e. no other requests
    // are currently being processed. This effectively enforces "one
    // compilation request at a time".
    if (!isEmpty) {
      return;
    }

    bool isFirst = true;

    while (compilationQueue.isNotEmpty) {
      final _CompilationRequest request = compilationQueue.first;
      globals.printTrace('Compiling ${request.mainUri}');

      if (isFirst) {
        globals.printTrace(
          "Generating registrant for project:'${flutterProject.directory}' thing:${request.mainUri}",
        );

        await generateProjectPluginRegistrant(
          flutterProject,
          buildInfo.packageConfig,
          globals.fs.file(request.mainUri),
        );

        isFirst = false;
      }

      final Stopwatch compilerTime = Stopwatch()..start();
      final Stopwatch? testTimeRecorderStopwatch = testTimeRecorder?.start(TestTimePhases.Compile);

      request._result.complete(await compiler.compile(request.mainUri));

      globals.printTrace('Compiling ${request.mainUri} took ${compilerTime.elapsedMilliseconds}ms');
      testTimeRecorder?.stop(TestTimePhases.Compile, testTimeRecorderStopwatch!);
      compilationQueue.removeAt(0);
    }
  }
}
