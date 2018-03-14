// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:usage/uuid/uuid.dart';

import 'artifacts.dart';
import 'base/io.dart';
import 'base/process_manager.dart';
import 'globals.dart';

class _StdoutHandler {
  _StdoutHandler() {
    reset();
  }

  String boundaryKey;
  Completer<String> outputFilename;

  void handler(String string) {
    const String kResultPrefix = 'result ';
    if (boundaryKey == null) {
      if (string.startsWith(kResultPrefix))
        boundaryKey = string.substring(kResultPrefix.length);
    } else if (string.startsWith(boundaryKey))
      outputFilename.complete(string.length > boundaryKey.length
        ? string.substring(boundaryKey.length + 1)
        : null);
    else
      printError('compiler message: $string');
  }

  // This is needed to get ready to process next compilation result output,
  // with its own boundary key and new completer.
  void reset() {
    boundaryKey = null;
    outputFilename = new Completer<String>();
  }
}

Future<String> compile(
    {String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    bool linkPlatformKernelIn: false,
    bool aot: false,
    List<String> entryPointsJsonFiles,
    bool trackWidgetCreation: false,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    String packagesPath}) async {
  final String frontendServer = artifacts.getArtifactPath(
    Artifact.frontendServerSnapshotForEngineDartSdk
  );

  // This is a URI, not a file path, so the forward slash is correct even on Windows.
  if (!sdkRoot.endsWith('/'))
    sdkRoot = '$sdkRoot/';
  final List<String> command = <String>[
    artifacts.getArtifactPath(Artifact.engineDartBinary),
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
  if (depFilePath != null) {
    command.addAll(<String>['--depfile', depFilePath]);
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
  return exitCode == 0 ? stdoutHandler.outputFilename.future : null;
}

/// Wrapper around incremental frontend server compiler, that communicates with
/// server via stdin/stdout.
///
/// The wrapper is intended to stay resident in memory as user changes, reloads,
/// restarts the Flutter app.
class ResidentCompiler {
  ResidentCompiler(this._sdkRoot, {bool trackWidgetCreation: false,
      String packagesPath})
    : assert(_sdkRoot != null),
      _trackWidgetCreation = trackWidgetCreation,
      _packagesPath = packagesPath {
    // This is a URI, not a file path, so the forward slash is correct even on Windows.
    if (!_sdkRoot.endsWith('/'))
      _sdkRoot = '$_sdkRoot/';
  }

  final bool _trackWidgetCreation;
  final String _packagesPath;
  String _sdkRoot;
  Process _server;
  final _StdoutHandler stdoutHandler = new _StdoutHandler();

  /// If invoked for the first time, it compiles Dart script identified by
  /// [mainPath], [invalidatedFiles] list is ignored.
  /// On successive runs [invalidatedFiles] indicates which files need to be
  /// recompiled. If [mainPath] is [null], previously used [mainPath] entry
  /// point that is used for recompilation.
  /// Binary file name is returned if compilation was successful, otherwise
  /// null is returned.
  Future<String> recompile(String mainPath, List<String> invalidatedFiles,
      {String outputPath, String packagesFilePath}) async {
    stdoutHandler.reset();

    // First time recompile is called we actually have to compile the app from
    // scratch ignoring list of invalidated files.
    if (_server == null)
      return _compile(mainPath, outputPath, packagesFilePath);

    final String inputKey = new Uuid().generateV4();
    _server.stdin.writeln('recompile ${mainPath != null ? mainPath + " ": ""}$inputKey');
    invalidatedFiles.forEach(_server.stdin.writeln);
    _server.stdin.writeln(inputKey);

    return stdoutHandler.outputFilename.future;
  }

  Future<String> _compile(String scriptFilename, String outputPath, String packagesFilePath) async {
    final String frontendServer = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    final List<String> args = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary),
      frontendServer,
      '--sdk-root',
      _sdkRoot,
      '--incremental',
      '--strong',
      '--target=flutter',
    ];
    if (outputPath != null) {
      args.addAll(<String>['--output-dill', outputPath]);
    }
    if (packagesFilePath != null) {
      args.addAll(<String>['--packages', packagesFilePath]);
    }
    if (_trackWidgetCreation) {
      args.add('--track-widget-creation');
    }
    if (_packagesPath != null) {
      args.addAll(<String>['--packages', _packagesPath]);
    }
    _server = await processManager.start(args);
    _server.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        stdoutHandler.handler,
        onDone: () {
          // when outputFilename future is not completed, but stdout is closed
          // process has died unexpectedly.
          if (!stdoutHandler.outputFilename.isCompleted) {
            stdoutHandler.outputFilename.complete(null);
          }
        });

    _server.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String s) { printError('compiler message: $s'); });

    _server.stdin.writeln('compile $scriptFilename');

    return stdoutHandler.outputFilename.future;
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
}
