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

  Future<void> maybeUpdateWith(File other, {required bool force}) async {
    if (force || !_created || (file.lengthSync() < other.lengthSync())) {
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

/// A frontend_server wrapper for the flutter test runner.
///
/// This class is a wrapper around compiler that allows multiple isolates to
/// enqueue compilation requests, but ensures only one compilation at a time.
class TestCompiler {
  final StreamController<_CompilationRequest> compilerController = StreamController();
  final List<_CompilationRequest> compilationQueue = [];
  final FlutterProject flutterProject;
  final BuildInfo buildInfo;
  final KernelCacheFile cacheKernelFile;
  final TestTimeRecorder? testTimeRecorder;

  ResidentCompiler? compiler;
  late File outputDill;

  /// Creates a new [TestCompiler] which acts as a frontend_server proxy.
  ///
  /// [trackWidgetCreation] configures whether the kernel transform is applied
  /// to the output. This also changes the output file to include a '.track`
  /// extension.
  ///
  /// [flutterProject] is the project for which we are running tests.
  ///
  /// If [precompiledDillPath] is passed, it will be used to initialize the
  /// compiler.
  ///
  /// If [testTimeRecorder] is passed, times will be recorded in it.
  TestCompiler(this.buildInfo, FlutterProject? flutterProject, {this.testTimeRecorder})
    : flutterProject = flutterProject!,
      cacheKernelFile = KernelCacheFile(
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
      ) {
    // Compiler maintains and updates single incremental dill file.
    // Incremental compilation requests done for each test copy that file away
    // for independent execution.
    final Directory outputDillDirectory = globals.fs.systemTempDirectory.createTempSync(
      'flutter_test_compiler.',
    );
    outputDill = outputDillDirectory.childFile('output.dill');
    globals.printTrace(
      'Compiler will use the following file as its incremental dill file: ${outputDill.path}',
    );

    globals.printTrace('Compiler will use the cache kernel path: ${cacheKernelFile}');

    globals.printTrace('Listening to compiler controller...');
    compilerController.stream.listen(
      _onCompilationRequest,
      onDone: () {
        globals.printTrace('Deleting ${outputDillDirectory.path}...');
        outputDillDirectory.deleteSync(recursive: true);
      },
    );
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
    // Check for null in case this instance is shut down before the
    // lazily-created compiler has been created.
    if (compiler != null) {
      await compiler!.shutdown();
      compiler = null;
    }
  }

  Future<void> dispose() async {
    await compilerController.close();
    await _shutdown();
  }

  /// Create the resident compiler used to compile the test.
  @visibleForTesting
  ResidentCompiler createCompiler() {
    return ResidentCompiler(
      globals.artifacts!.getArtifactPath(Artifact.flutterPatchedSdkPath),
      artifacts: globals.artifacts!,
      logger: globals.logger,
      processManager: globals.processManager,
      buildMode: buildInfo.mode,
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      initializeFromDill: cacheKernelFile.path,
      dartDefines: buildInfo.dartDefines,
      packagesPath: buildInfo.packageConfigPath,
      frontendServerStarterPath: buildInfo.frontendServerStarterPath,
      extraFrontEndOptions: buildInfo.extraFrontEndOptions,
      platform: globals.platform,
      testCompilation: true,
      fileSystem: globals.fs,
      fileSystemRoots: buildInfo.fileSystemRoots,
      fileSystemScheme: buildInfo.fileSystemScheme,
    );
  }

  // Handle a compilation request.
  Future<void> _onCompilationRequest(_CompilationRequest request) async {
    final bool isEmpty = compilationQueue.isEmpty;
    compilationQueue.add(request);
    // Only trigger processing if queue was empty - i.e. no other requests
    // are currently being processed. This effectively enforces "one
    // compilation request at a time".
    if (!isEmpty) {
      return;
    }
    while (compilationQueue.isNotEmpty) {
      final _CompilationRequest request = compilationQueue.first;
      globals.printTrace('Compiling ${request.mainUri}');
      final Stopwatch compilerTime = Stopwatch()..start();
      final Stopwatch? testTimeRecorderStopwatch = testTimeRecorder?.start(TestTimePhases.Compile);
      bool firstCompile = false;
      if (compiler == null) {
        compiler = createCompiler();
        firstCompile = true;

        globals.printTrace(
          "Generating registrant for project:'${flutterProject.directory}' thing:${request.mainUri}",
        );
        await generateProjectPluginRegistrant(
          flutterProject,
          buildInfo.packageConfig,
          globals.fs.file(request.mainUri),
        );
      }

      final CompilerOutput? compilerOutput = await compiler!.recompile(
        request.mainUri,
        <Uri>[request.mainUri, flutterProject.dartPluginRegistrant.absolute.uri],
        outputPath: outputDill.path,
        packageConfig: buildInfo.packageConfig,
        projectRootPath: flutterProject.directory.absolute.path,
        checkDartPluginRegistry: true,
        fs: globals.fs,
      );

      // In case compiler didn't produce output or reported compilation
      // errors, pass [null] upwards to the consumer and shutdown the
      // compiler to avoid reusing compiler that might have gotten into
      // a weird state.
      if (compilerOutput == null || compilerOutput.errorCount > 0) {
        request._result.complete(
          TestCompilerFailure(
            error: compilerOutput!.errorMessage ?? 'Unknown Error',
            mainUri: request.mainUri,
          ),
        );
        await _shutdown();
      } else {
        final String path = request.mainUri.toFilePath(windows: globals.platform.isWindows);
        final File compilerOutputFile = globals.fs.file(compilerOutput.outputFilename);
        final File kernelReadyToRun = await compilerOutputFile.copy('$path.dill');

        await cacheKernelFile.maybeUpdateWith(compilerOutputFile, force: firstCompile);

        request._result.complete(
          TestCompilerComplete(outputPath: kernelReadyToRun.path, mainUri: request.mainUri),
        );
        compiler!.accept();
        compiler!.reset();
      }
      globals.printTrace('Compiling ${request.mainUri} took ${compilerTime.elapsedMilliseconds}ms');
      testTimeRecorder?.stop(TestTimePhases.Compile, testTimeRecorderStopwatch!);
      // Only remove now when we finished processing the element
      compilationQueue.removeAt(0);
    }
  }
}
