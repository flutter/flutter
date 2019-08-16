// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as prefix0;

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../compile.dart';
import '../dart/package_map.dart';
import '../globals.dart';

class _CompilationRequest {
  _CompilationRequest(this.path, this.result, {List<Uri> invalidatedFiles = const <Uri>[]}) {
    this.invalidatedFiles = <Uri>[Uri.parse(path)];
    this.invalidatedFiles.addAll(invalidatedFiles);
  }
  String path;
  Completer<String> result;
  List<Uri> invalidatedFiles;
}

// This class is a wrapper around compiler that allows multiple isolates to
// enqueue compilation requests, but ensures only one compilation at a time.
class TestCompiler {
  TestCompiler(bool trackWidgetCreation, Uri projectRootDirectory) {
    // Compiler maintains and updates single incremental dill file.
    // Incremental compilation requests done for each test copy that file away
    // for independent execution.
    final Directory outputDillDirectory = fs.systemTempDirectory.createTempSync('flutter_test_compiler.');
    final File outputDill = outputDillDirectory.childFile('output.dill');

    printTrace('Compiler will use the following file as its incremental dill file: ${outputDill.path}');

    bool suppressOutput = false;
    void reportCompilerMessage(String message, {bool emphasis, TerminalColor color}) {
      if (suppressOutput) {
        return;
      }

      if (message.startsWith('Error: Could not resolve the package \'flutter_test\'')) {
        printTrace(message);
        printError('\n\nFailed to load test harness. Are you missing a dependency on flutter_test?\n',
          emphasis: emphasis,
          color: color,
        );
        suppressOutput = true;
        return;
      }

      printError('$message');
    }

    final String testFilePath = getKernelPathForTransformerOptions(
      fs.path.join(fs.path.fromUri(projectRootDirectory), getBuildDirectory(), 'testfile.dill'),
      trackWidgetCreation: trackWidgetCreation,
    );

    ResidentCompiler createCompiler() {
      return ResidentCompiler(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
        packagesPath: PackageMap.globalPackagesPath,
        trackWidgetCreation: trackWidgetCreation,
        compilerMessageConsumer: reportCompilerMessage,
        initializeFromDill: testFilePath,
        unsafePackageSerialization: false,
      );
    }

    printTrace('Listening to compiler controller...');
    compilerController.stream.listen((_CompilationRequest request) async {
      final bool isEmpty = compilationQueue.isEmpty;
      compilationQueue.add(request);
      // Only trigger processing if queue was empty - i.e. no other requests
      // are currently being processed. This effectively enforces "one
      // compilation request at a time".
      if (isEmpty) {
        while (compilationQueue.isNotEmpty) {
          final _CompilationRequest request = compilationQueue.first;
          printTrace('Compiling ${request.path}');
          final Stopwatch compilerTime = Stopwatch()..start();
          bool firstCompile = false;
          if (compiler == null) {
            compiler = createCompiler();
            firstCompile = true;
          }
          suppressOutput = false;
          final CompilerOutput compilerOutput = await handleTimeout<CompilerOutput>(
            compiler.recompile(
              request.path,
              request.invalidatedFiles,
              outputPath: outputDill.path),
              request.path,
            );
          final String outputPath = compilerOutput?.outputFilename;

          // In case compiler didn't produce output or reported compilation
          // errors, pass [null] upwards to the consumer and shutdown the
          // compiler to avoid reusing compiler that might have gotten into
          // a weird state.
          if (outputPath == null || compilerOutput.errorCount > 0) {
            request.result.complete(null);
            await _shutdown();
          } else {
            final File outputFile = fs.file(outputPath);
            final File kernelReadyToRun = await outputFile.copy('${request.path}.dill');
            final File testCache = fs.file(testFilePath);
            if (firstCompile || !testCache.existsSync() || (testCache.lengthSync() < outputFile.lengthSync())) {
              // The idea is to keep the cache file up-to-date and include as
              // much as possible in an effort to re-use as many packages as
              // possible.
              ensureDirectoryExists(testFilePath);
              await outputFile.copy(testFilePath);
            }
            request.result.complete(kernelReadyToRun.path);
            compiler.accept();
            compiler.reset();
          }
          printTrace('Compiling ${request.path} took ${compilerTime.elapsedMilliseconds}ms');
          // Only remove now when we finished processing the element
          compilationQueue.removeAt(0);
        }
      }
    }, onDone: () {
      printTrace('Deleting ${outputDillDirectory.path}...');
      outputDillDirectory.deleteSync(recursive: true);
    });
  }

  final StreamController<_CompilationRequest> compilerController = StreamController<_CompilationRequest>();
  final List<_CompilationRequest> compilationQueue = <_CompilationRequest>[];
  ResidentCompiler compiler;

  Future<String> compile(String mainDart, {List<Uri> invalidatedFiles = const <Uri>[]}) {
    final Completer<String> completer = Completer<String>();
    compilerController.add(
      _CompilationRequest(
        mainDart,
        completer,
        invalidatedFiles: invalidatedFiles
      )
    );
    return handleTimeout<String>(completer.future, mainDart);
  }

  Future<void> _shutdown() async {
    // Check for null in case this instance is shut down before the
    // lazily-created compiler has been created.
    if (compiler != null) {
      await compiler.shutdown();
      compiler = null;
    }
  }

  Future<void> dispose() async {
    await _shutdown();
    await compilerController.close();
  }

  static Future<T> handleTimeout<T>(Future<T> value, String path) {
    return value.timeout(const Duration(minutes: 5), onTimeout: () {
      printError('Compilation of $path timed out after 5 minutes.');
      return null;
    });
  }
}
