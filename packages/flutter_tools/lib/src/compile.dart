// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:usage/uuid/uuid.dart';

import 'artifacts.dart';
import 'base/common.dart';
import 'base/context.dart';
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
  _StdoutHandler({this.consumer: printError}) {
    reset();
  }

  final CompilerMessageConsumer consumer;
  String boundaryKey;
  Completer<CompilerOutput> compilerOutput;

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
    else
      consumer('compiler message: $string');
  }

  // This is needed to get ready to process next compilation result output,
  // with its own boundary key and new completer.
  void reset() {
    boundaryKey = null;
    compilerOutput = new Completer<CompilerOutput>();
  }
}

class KernelCompiler {
  const KernelCompiler();

  Future<CompilerOutput> compile({
    String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    bool linkPlatformKernelIn: false,
    bool aot: false,
    List<String> entryPointsJsonFiles,
    bool trackWidgetCreation: false,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
  }) async {
    final String frontendServer = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );

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

    final _StdoutHandler stdoutHandler = new _StdoutHandler();

    server.stderr
      .transform(utf8.decoder)
      .listen((String s) { printError('compiler message: $s'); });
    server.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(stdoutHandler.handler);
    final int exitCode = await server.exitCode;
    return exitCode == 0 ? stdoutHandler.compilerOutput.future : null;
  }
}

/// Wrapper around incremental frontend server compiler, that communicates with
/// server via stdin/stdout.
///
/// The wrapper is intended to stay resident in memory as user changes, reloads,
/// restarts the Flutter app.
class ResidentCompiler {
  ResidentCompiler(this._sdkRoot, {bool trackWidgetCreation: false,
      String packagesPath, List<String> fileSystemRoots, String fileSystemScheme ,
      CompilerMessageConsumer compilerMessageConsumer: printError})
    : assert(_sdkRoot != null),
      _trackWidgetCreation = trackWidgetCreation,
      _packagesPath = packagesPath,
      _fileSystemRoots = fileSystemRoots,
      _fileSystemScheme = fileSystemScheme,
      stdoutHandler = new _StdoutHandler(consumer: compilerMessageConsumer) {
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
  final _StdoutHandler stdoutHandler;

  /// If invoked for the first time, it compiles Dart script identified by
  /// [mainPath], [invalidatedFiles] list is ignored.
  /// On successive runs [invalidatedFiles] indicates which files need to be
  /// recompiled. If [mainPath] is [null], previously used [mainPath] entry
  /// point that is used for recompilation.
  /// Binary file name is returned if compilation was successful, otherwise
  /// null is returned.
  Future<CompilerOutput> recompile(String mainPath, List<String> invalidatedFiles,
      {String outputPath, String packagesFilePath}) async {
    stdoutHandler.reset();

    // First time recompile is called we actually have to compile the app from
    // scratch ignoring list of invalidated files.
    if (_server == null)
      return _compile(_mapFilename(mainPath), outputPath, _mapFilename(packagesFilePath));

    final String inputKey = new Uuid().generateV4();
    _server.stdin.writeln('recompile ${mainPath != null ? _mapFilename(mainPath) + " ": ""}$inputKey');
    for (String fileUri in invalidatedFiles) {
      _server.stdin.writeln(_mapFileUri(fileUri));
    }
    _server.stdin.writeln(inputKey);

    return stdoutHandler.compilerOutput.future;
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
        stdoutHandler.handler,
        onDone: () {
          // when outputFilename future is not completed, but stdout is closed
          // process has died unexpectedly.
          if (!stdoutHandler.compilerOutput.isCompleted) {
            stdoutHandler.compilerOutput.complete(null);
          }
        });

    _server.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String s) { printError('compiler message: $s'); });

    _server.stdin.writeln('compile $scriptFilename');

    return stdoutHandler.compilerOutput.future;
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
    _server.stdin.writeln('reset');
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
