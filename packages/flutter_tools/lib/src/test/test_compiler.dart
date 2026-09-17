// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../compile.dart';
import '../context/tool_context.dart';
import '../dart/language_version.dart';
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
  final _result = Completer<TestCompilerResult>();
}

/// The result of [TestCompiler.compile].
@immutable
sealed class TestCompilerResult {
  const TestCompilerResult({required this.mainUri});

  /// The program that was or was attempted to be compiled.
  final Uri mainUri;
}

/// A successful run of [TestCompiler.compile].
final class TestCompilerComplete extends TestCompilerResult {
  const TestCompilerComplete({required this.outputPath, required super.mainUri});

  /// Output path of the compiled program.
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

/// A frontend_server wrapper for the flutter test runner.
///
/// This class is a wrapper around compiler that allows multiple isolates to
/// enqueue compilation requests, but ensures only one compilation at a time.
class TestCompiler {
  /// Creates a new [TestCompiler] which acts as a frontend_server proxy.
  ///
  /// [BuildInfo.trackWidgetCreation] configures whether
  /// the kernel transform is applied to the output.
  /// This also changes the output file to include a '.track` extension.
  ///
  /// [flutterProject] is the project for which we are running tests.
  ///
  /// If [precompiledDillPath] is passed, it will be used to initialize the
  /// compiler.
  ///
  /// If [testTimeRecorder] is passed, times will be recorded in it.
  TestCompiler(
    BuildInfo buildInfo,
    this.flutterProject, {
    ToolContext? toolContext,
    String? precompiledDillPath,
    this.residentCompilerFactory = const ResidentCompilerFactory(),
    this.testTimeRecorder,
  }) : _toolContext = toolContext ?? _FallbackToolContext(),
       testFilePath =
           precompiledDillPath ??
           _computeTestFilePath(toolContext ?? _FallbackToolContext(), flutterProject, buildInfo),
       shouldCopyDillFile = precompiledDillPath == null {
    this.buildInfo = buildInfo.copyWith(initializeFromDill: testFilePath);
    final ToolContext(:FileSystem fs, :Logger logger) = _toolContext;
    // Compiler maintains and updates single incremental dill file.
    // Incremental compilation requests done for each test copy that file away
    // for independent execution.
    final Directory outputDillDirectory = fs.systemTempDirectory.createTempSync(
      'flutter_test_compiler.',
    );
    outputDill = outputDillDirectory.childFile('output.dill');
    logger.printTrace(
      'Compiler will use the following file as its incremental dill file: ${outputDill.path}',
    );
    logger.printTrace('Listening to compiler controller...');
    compilerController.stream.listen(
      _onCompilationRequest,
      onDone: () {
        logger.printTrace('Deleting ${outputDillDirectory.path}...');
        outputDillDirectory.deleteSync(recursive: true);
      },
    );
  }

  static String _computeTestFilePath(
    ToolContext toolContext,
    FlutterProject? flutterProject,
    BuildInfo buildInfo,
  ) {
    final ToolContext(:Config config, :FileSystem fs) = toolContext;
    return fs.path.join(
      flutterProject!.directory.path,
      getBuildDirectory(),
      'test_cache',
      getDefaultCachedKernelPath(
        config: config,
        fileSystem: fs,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        dartDefines: buildInfo.dartDefines,
        targetModel: TargetModel.flutter,
        extraFrontEndOptions: buildInfo.extraFrontEndOptions,
      ),
    );
  }

  final compilerController = StreamController<_CompilationRequest>();
  final compilationQueue = <_CompilationRequest>[];
  final FlutterProject? flutterProject;
  late final BuildInfo buildInfo;
  final String testFilePath;
  final bool shouldCopyDillFile;
  final TestTimeRecorder? testTimeRecorder;
  final ResidentCompilerFactory residentCompilerFactory;

  final ToolContext _toolContext;

  ResidentCompiler? compiler;
  late File outputDill;

  /// The language version the plugin registrant was last generated for, or
  /// `null` if it hasn't been generated yet. The plugin set is stable for the
  /// lifetime of a single `flutter test` run, so the registrant only needs to
  /// be regenerated when the language version of the entrypoint changes (e.g.
  /// when test files come from packages with different `// @dart =` versions).
  LanguageVersion? _registrantLanguageVersion;

  /// Compiles the Dart program (an entrypoint containing `main()`).
  Future<TestCompilerResult> compile(Uri dartEntrypointPath) {
    if (compilerController.isClosed) {
      throw StateError('TestCompiler is already disposed.');
    }
    final request = _CompilationRequest(dartEntrypointPath);
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
  Future<ResidentCompiler?> createCompiler() async {
    final ToolContext(
      :Artifacts artifacts,
      :Config config,
      :FileSystem fs,
      :Logger logger,
      :Platform platform,
      :ProcessManager processManager,
      :ShutdownHooks shutdownHooks,
    ) = _toolContext;
    final ResidentCompiler residentCompiler = residentCompilerFactory.create(
      artifacts: artifacts,
      logger: logger,
      processManager: processManager,
      buildInfo: buildInfo,
      platform: platform,
      testCompilation: true,
      fileSystem: fs,
      shutdownHooks: shutdownHooks,
      config: config,
      targetPlatform: TargetPlatform.tester,
    );
    return residentCompiler;
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
    final ToolContext(:FileSystem fs, :Logger logger, :Platform platform) = _toolContext;
    while (compilationQueue.isNotEmpty) {
      final _CompilationRequest request = compilationQueue.first;
      logger.printTrace('Compiling ${request.mainUri}');
      final compilerTime = Stopwatch()..start();
      final Stopwatch? testTimeRecorderStopwatch = testTimeRecorder?.start(TestTimePhases.Compile);
      var firstCompile = false;
      if (compiler == null) {
        compiler = await createCompiler();
        firstCompile = true;
      }

      final invalidatedRegistrantFiles = <Uri>[];
      if (flutterProject != null) {
        final File mainFile = fs.file(request.mainUri);
        final LanguageVersion languageVersion = determineLanguageVersion(
          mainFile,
          buildInfo.packageConfig.packageOf(request.mainUri),
          Cache.flutterRoot!,
        );
        if (languageVersion != _registrantLanguageVersion) {
          // (Re)generate the registrant. The output is keyed only on the plugin
          // set (stable for one `flutter test` run) and the entrypoint's
          // language version, so we can skip this work when the language
          // version matches the previous compilation.
          await generateMainDartWithPluginRegistrant(
            flutterProject!,
            buildInfo.packageConfig,
            mainFile,
          );
          invalidatedRegistrantFiles.add(flutterProject!.dartPluginRegistrant.absolute.uri);
          _registrantLanguageVersion = languageVersion;
        }
      }

      final CompilerOutput? compilerOutput = await compiler!.recompile(
        request.mainUri,
        <Uri>[request.mainUri, ...invalidatedRegistrantFiles],
        outputPath: outputDill.path,
        packageConfig: buildInfo.packageConfig,
        projectRootPath: flutterProject?.directory.absolute.path,
        checkDartPluginRegistry: true,
        fs: fs,
      );
      final String? outputPath = compilerOutput?.outputFilename;

      // In case compiler didn't produce output or reported compilation
      // errors, pass [null] upwards to the consumer and shutdown the
      // compiler to avoid reusing compiler that might have gotten into
      // a weird state.
      if (outputPath == null || compilerOutput!.errorCount > 0) {
        request._result.complete(
          TestCompilerFailure(
            error: compilerOutput!.errorMessage ?? 'Unknown Error',
            mainUri: request.mainUri,
          ),
        );
        await _shutdown();
      } else {
        if (shouldCopyDillFile) {
          final String path = request.mainUri.toFilePath(windows: platform.isWindows);
          final File outputFile = fs.file(outputPath);
          final File kernelReadyToRun = await outputFile.copy('$path.dill');
          final File testCache = fs.file(testFilePath);
          if (firstCompile ||
              !testCache.existsSync() ||
              (testCache.lengthSync() < outputFile.lengthSync())) {
            // The idea is to keep the cache file up-to-date and include as
            // much as possible in an effort to re-use as many packages as
            // possible.
            if (!testCache.parent.existsSync()) {
              testCache.parent.createSync(recursive: true);
            }
            await outputFile.copy(testFilePath);
          }
          request._result.complete(
            TestCompilerComplete(outputPath: kernelReadyToRun.path, mainUri: request.mainUri),
          );
        } else {
          request._result.complete(
            TestCompilerComplete(outputPath: outputPath, mainUri: request.mainUri),
          );
        }
        compiler!.accept();
        compiler!.reset();
      }
      logger.printTrace('Compiling ${request.mainUri} took ${compilerTime.elapsedMilliseconds}ms');
      testTimeRecorder?.stop(TestTimePhases.Compile, testTimeRecorderStopwatch!);
      // Only remove now when we finished processing the element
      compilationQueue.removeAt(0);
    }
  }
}

class _FallbackToolContext implements ToolContext {
  _FallbackToolContext();

  @override
  Artifacts get artifacts => globals.artifacts!;

  @override
  Config get config => globals.config;

  @override
  FileSystem get fs => globals.fs;

  @override
  Logger get logger => globals.logger;

  @override
  OperatingSystemUtils get os => globals.os;

  @override
  Platform get platform => globals.platform;

  @override
  ProcessManager get processManager => globals.processManager;

  @override
  ProcessUtils get processUtils => globals.processUtils;

  @override
  ShutdownHooks get shutdownHooks => globals.shutdownHooks;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
