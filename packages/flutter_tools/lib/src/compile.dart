// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:usage/uuid/uuid.dart';

import 'artifacts.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/fingerprint.dart';
import 'base/io.dart';
import 'base/process_manager.dart';
import 'globals.dart';

KernelCompiler get kernelCompiler => context[KernelCompiler];

typedef void CompilerMessageConsumer(String message);

class CompilerOutput {
  final String outputFilename;
  final int errorCount;

  const CompilerOutput(this.outputFilename, this.errorCount);
}

class _StdoutHandler {
  _StdoutHandler({this.consumer = printError}) {
    reset();
  }

  final CompilerMessageConsumer consumer;
  String boundaryKey;
  Completer<CompilerOutput> compilerOutput;

  bool _suppressCompilerMessages;

  void handler(String string) {
    const String kResultPrefix = 'result ';
    if (boundaryKey == null) {
      if (string.startsWith(kResultPrefix))
        boundaryKey = string.substring(kResultPrefix.length);
    } else if (string.startsWith(boundaryKey)) {
      if (string.length <= boundaryKey.length) {
        compilerOutput.complete(null);
        return;
      }
      final int spaceDelimiter = string.lastIndexOf(' ');
      compilerOutput.complete(
        new CompilerOutput(
          string.substring(boundaryKey.length + 1, spaceDelimiter),
          int.parse(string.substring(spaceDelimiter + 1).trim())));
    }
    else if (!_suppressCompilerMessages) {
      consumer('compiler message: $string');
    }
  }

  // This is needed to get ready to process next compilation result output,
  // with its own boundary key and new completer.
  void reset({bool suppressCompilerMessages = false}) {
    boundaryKey = null;
    compilerOutput = new Completer<CompilerOutput>();
    _suppressCompilerMessages = suppressCompilerMessages;
  }
}

class KernelCompiler {
  const KernelCompiler();

  Future<CompilerOutput> compile({
    String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    List<String> entryPointsJsonFiles,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    bool targetProductVm = false,
  }) async {
    final String frontendServer = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );

    // TODO(cbracken): eliminate pathFilter.
    // Currently the compiler emits buildbot paths for the core libs in the
    // depfile. None of these are available on the local host.
    Fingerprinter fingerprinter;
    if (depFilePath != null) {
      fingerprinter = new Fingerprinter(
        fingerprintPath: '$depFilePath.fingerprint',
        paths: <String>[mainPath],
        properties: <String, String>{
          'entryPoint': mainPath,
          'trackWidgetCreation': trackWidgetCreation.toString(),
          'linkPlatformKernelIn': linkPlatformKernelIn.toString(),
        },
        depfilePaths: <String>[depFilePath],
        pathFilter: (String path) => !path.startsWith('/b/build/slave/'),
      );

      if (await fingerprinter.doesFingerprintMatch()) {
        printTrace('Skipping kernel compilation. Fingerprint match.');
        return new CompilerOutput(outputFilePath, 0);
      }
    }

    // This is a URI, not a file path, so the forward slash is correct even on Windows.
    if (!sdkRoot.endsWith('/'))
      sdkRoot = '$sdkRoot/';
    final String engineDartPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    if (!processManager.canRun(engineDartPath)) {
      throwToolExit('Unable to find Dart binary at $engineDartPath');
    }
    final List<String> command = <String>[
      engineDartPath,
      frontendServer,
      '--sdk-root',
      sdkRoot,
      '--strong',
      '--target=flutter',
    ];
    if (trackWidgetCreation)
      command.add('--track-widget-creation');
    if (!linkPlatformKernelIn)
      command.add('--no-link-platform');
    if (aot) {
      command.add('--aot');
      command.add('--tfa');
    }
    if (targetProductVm) {
      command.add('-Ddart.vm.product=true');
    }
    if (entryPointsJsonFiles != null) {
      for (String entryPointsJson in entryPointsJsonFiles) {
        command.addAll(<String>['--entry-points', entryPointsJson]);
      }
    }
    if (incrementalCompilerByteStorePath != null) {
      command.add('--incremental');
    }
    if (packagesPath != null) {
      command.addAll(<String>['--packages', packagesPath]);
    }
    if (outputFilePath != null) {
      command.addAll(<String>['--output-dill', outputFilePath]);
    }
    if (depFilePath != null && (fileSystemRoots == null || fileSystemRoots.isEmpty)) {
      command.addAll(<String>['--depfile', depFilePath]);
    }
    if (fileSystemRoots != null) {
      for (String root in fileSystemRoots) {
        command.addAll(<String>['--filesystem-root', root]);
      }
    }
    if (fileSystemScheme != null) {
      command.addAll(<String>['--filesystem-scheme', fileSystemScheme]);
    }

    if (extraFrontEndOptions != null)
      command.addAll(extraFrontEndOptions);
    command.add(mainPath);
    printTrace(command.join(' '));
    final Process server = await processManager
        .start(command)
        .catchError((dynamic error, StackTrace stack) {
      printError('Failed to start frontend server $error, $stack');
    });

    final _StdoutHandler _stdoutHandler = new _StdoutHandler();

    server.stderr
      .transform(utf8.decoder)
      .listen((String s) { printError('compiler message: $s'); });
    server.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(_stdoutHandler.handler);
    final int exitCode = await server.exitCode;
    if (exitCode == 0) {
      if (fingerprinter != null) {
        await fingerprinter.writeFingerprint();
      }
      return _stdoutHandler.compilerOutput.future;
    }
    return null;
  }
}

/// Class that allows to serialize compilation requests to the compiler.
abstract class _CompilationRequest {
  Completer<CompilerOutput> completer;

  _CompilationRequest(this.completer);

  Future<CompilerOutput> _run(ResidentCompiler compiler);

  Future<void> run(ResidentCompiler compiler) async {
    completer.complete(await _run(compiler));
  }
}

class _RecompileRequest extends _CompilationRequest {
  _RecompileRequest(Completer<CompilerOutput> completer, this.mainPath,
      this.invalidatedFiles, this.outputPath, this.packagesFilePath) :
      super(completer);

  String mainPath;
  List<String> invalidatedFiles;
  String outputPath;
  String packagesFilePath;

  @override
  Future<CompilerOutput> _run(ResidentCompiler compiler) async =>
      compiler._recompile(this);
}

class _CompileExpressionRequest extends _CompilationRequest {
  _CompileExpressionRequest(Completer<CompilerOutput> completer, this.expression, this.definitions,
      this.typeDefinitions, this.libraryUri, this.klass, this.isStatic) :
      super(completer);

  String expression;
  List<String> definitions;
  List<String> typeDefinitions;
  String libraryUri;
  String klass;
  bool isStatic;

  @override
  Future<CompilerOutput> _run(ResidentCompiler compiler) async =>
      compiler._compileExpression(this);
}

/// Wrapper around incremental frontend server compiler, that communicates with
/// server via stdin/stdout.
///
/// The wrapper is intended to stay resident in memory as user changes, reloads,
/// restarts the Flutter app.
class ResidentCompiler {
  ResidentCompiler(this._sdkRoot, {bool trackWidgetCreation = false,
      String packagesPath, List<String> fileSystemRoots, String fileSystemScheme ,
      CompilerMessageConsumer compilerMessageConsumer = printError})
    : assert(_sdkRoot != null),
      _trackWidgetCreation = trackWidgetCreation,
      _packagesPath = packagesPath,
      _fileSystemRoots = fileSystemRoots,
      _fileSystemScheme = fileSystemScheme,
      _stdoutHandler = new _StdoutHandler(consumer: compilerMessageConsumer),
      _controller = new StreamController<_CompilationRequest>() {
    // This is a URI, not a file path, so the forward slash is correct even on Windows.
    if (!_sdkRoot.endsWith('/'))
      _sdkRoot = '$_sdkRoot/';
  }

  final bool _trackWidgetCreation;
  final String _packagesPath;
  final List<String> _fileSystemRoots;
  final String _fileSystemScheme;
  String _sdkRoot;
  Process _server;
  final _StdoutHandler _stdoutHandler;

  final StreamController<_CompilationRequest> _controller;

  /// If invoked for the first time, it compiles Dart script identified by
  /// [mainPath], [invalidatedFiles] list is ignored.
  /// On successive runs [invalidatedFiles] indicates which files need to be
  /// recompiled. If [mainPath] is [null], previously used [mainPath] entry
  /// point that is used for recompilation.
  /// Binary file name is returned if compilation was successful, otherwise
  /// null is returned.
  Future<CompilerOutput> recompile(String mainPath, List<String> invalidatedFiles,
      {String outputPath, String packagesFilePath}) async {
    if (!_controller.hasListener) {
      _controller.stream.listen(_handleCompilationRequest);
    }

    final Completer<CompilerOutput> completer = new Completer<CompilerOutput>();
    _controller.add(
        new _RecompileRequest(completer, mainPath, invalidatedFiles, outputPath, packagesFilePath)
    );
    return completer.future;
  }

  Future<CompilerOutput> _recompile(_RecompileRequest request) async {
    _stdoutHandler.reset();

    // First time recompile is called we actually have to compile the app from
    // scratch ignoring list of invalidated files.
    if (_server == null) {
      return _compile(_mapFilename(request.mainPath),
          request.outputPath, _mapFilename(request.packagesFilePath));
    }

    final String inputKey = new Uuid().generateV4();
    _server.stdin.writeln('recompile ${request.mainPath != null ? _mapFilename(request.mainPath) + " ": ""}$inputKey');
    for (String fileUri in request.invalidatedFiles) {
      _server.stdin.writeln(_mapFileUri(fileUri));
    }
    _server.stdin.writeln(inputKey);

    return _stdoutHandler.compilerOutput.future;
  }

  final List<_CompilationRequest> compilationQueue = <_CompilationRequest>[];

  void _handleCompilationRequest(_CompilationRequest request) async {
    final bool isEmpty = compilationQueue.isEmpty;
    compilationQueue.add(request);
    // Only trigger processing if queue was empty - i.e. no other requests
    // are currently being processed. This effectively enforces "one
    // compilation request at a time".
    if (isEmpty) {
      while (compilationQueue.isNotEmpty) {
        final _CompilationRequest request = compilationQueue.first;
        await request.run(this);
        compilationQueue.removeAt(0);
      }
    }
  }

  Future<CompilerOutput> _compile(String scriptFilename, String outputPath,
      String packagesFilePath) async {
    final String frontendServer = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    final List<String> command = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary),
      frontendServer,
      '--sdk-root',
      _sdkRoot,
      '--incremental',
      '--strong',
      '--target=flutter',
      '--initialize-from-dill=foo' // TODO(aam): remove once dartbug.com/33087 fixed
    ];
    if (outputPath != null) {
      command.addAll(<String>['--output-dill', outputPath]);
    }
    if (packagesFilePath != null) {
      command.addAll(<String>['--packages', packagesFilePath]);
    }
    if (_trackWidgetCreation) {
      command.add('--track-widget-creation');
    }
    if (_packagesPath != null) {
      command.addAll(<String>['--packages', _packagesPath]);
    }
    if (_fileSystemRoots != null) {
      for (String root in _fileSystemRoots) {
        command.addAll(<String>['--filesystem-root', root]);
      }
    }
    if (_fileSystemScheme != null) {
      command.addAll(<String>['--filesystem-scheme', _fileSystemScheme]);
    }
    printTrace(command.join(' '));
    _server = await processManager.start(command);
    _server.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        _stdoutHandler.handler,
        onDone: () {
          // when outputFilename future is not completed, but stdout is closed
          // process has died unexpectedly.
          if (!_stdoutHandler.compilerOutput.isCompleted) {
            _stdoutHandler.compilerOutput.complete(null);
          }
        });

    _server.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String s) { printError('compiler message: $s'); });

    _server.stdin.writeln('compile $scriptFilename');

    return _stdoutHandler.compilerOutput.future;
  }

  Future<CompilerOutput> compileExpression(String expression, List<String> definitions,
      List<String> typeDefinitions, String libraryUri, String klass, bool isStatic) {
    if (!_controller.hasListener) {
      _controller.stream.listen(_handleCompilationRequest);
    }

    final Completer<CompilerOutput> completer = new Completer<CompilerOutput>();
    _controller.add(
        new _CompileExpressionRequest(
            completer, expression, definitions, typeDefinitions, libraryUri, klass, isStatic)
    );
    return completer.future;
  }

  Future<CompilerOutput> _compileExpression(
      _CompileExpressionRequest request) async {
    _stdoutHandler.reset(suppressCompilerMessages: true);

    // 'compile-expression' should be invoked after compiler has been started,
    // program was compiled.
    if (_server == null)
      return null;

    final String inputKey = new Uuid().generateV4();
    _server.stdin.writeln('compile-expression $inputKey');
    _server.stdin.writeln(request.expression);
    request.definitions?.forEach(_server.stdin.writeln);
    _server.stdin.writeln(inputKey);
    request.typeDefinitions?.forEach(_server.stdin.writeln);
    _server.stdin.writeln(inputKey);
    _server.stdin.writeln(request.libraryUri ?? '');
    _server.stdin.writeln(request.klass ?? '');
    _server.stdin.writeln(request.isStatic ?? false);

    return _stdoutHandler.compilerOutput.future;
  }

  /// Should be invoked when results of compilation are accepted by the client.
  ///
  /// Either [accept] or [reject] should be called after every [recompile] call.
  void accept() {
    _server.stdin.writeln('accept');
  }

  /// Should be invoked when results of compilation are rejected by the client.
  ///
  /// Either [accept] or [reject] should be called after every [recompile] call.
  void reject() {
    _server.stdin.writeln('reject');
  }

  /// Should be invoked when frontend server compiler should forget what was
  /// accepted previously so that next call to [recompile] produces complete
  /// kernel file.
  void reset() {
    _server?.stdin?.writeln('reset');
  }

  String _mapFilename(String filename) {
    if (_fileSystemRoots != null) {
      for (String root in _fileSystemRoots) {
        if (filename.startsWith(root)) {
          return new Uri(
              scheme: _fileSystemScheme, path: filename.substring(root.length))
              .toString();
        }
      }
    }
    return filename;
  }

  String _mapFileUri(String fileUri) {
    if (_fileSystemRoots != null) {
      final String filename = Uri.parse(fileUri).toFilePath();
      for (String root in _fileSystemRoots) {
        if (filename.startsWith(root)) {
          return new Uri(
              scheme: _fileSystemScheme, path: filename.substring(root.length))
              .toString();
        }
      }
    }
    return fileUri;
  }

  Future<dynamic> shutdown() {
    _server.kill();
    return _server.exitCode;
  }
}
