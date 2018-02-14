// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:usage/uuid/uuid.dart';

import 'artifacts.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/process_manager.dart';
import 'globals.dart';

String _dartExecutable() {
  final String engineDartSdkPath = artifacts.getArtifactPath(
    Artifact.engineDartSdkPath
  );
  if (!fs.isDirectorySync(engineDartSdkPath)) {
    throwToolExit('No dart sdk Flutter host engine build found at $engineDartSdkPath.\n'
      'Note that corresponding host engine build is required even when targeting particular device platforms.',
      exitCode: 2);
  }
  return fs.path.join(engineDartSdkPath, 'bin', 'dart');
}

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
    bool linkPlatformKernelIn: false,
    bool aot: false,
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
    _dartExecutable(),
    frontendServer,
    '--sdk-root',
    sdkRoot,
    '--strong',
  ];
  if (trackWidgetCreation)
    command.add('--track-widget-creation');
  if (!linkPlatformKernelIn)
    command.add('--no-link-platform');
  if (aot) {
    command.add('--aot');
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
    .transform(UTF8.decoder)
    .listen((String s) { printError('compiler message: $s'); });
  server.stdout
    .transform(UTF8.decoder)
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
  ResidentCompiler(this._sdkRoot, {bool trackWidgetCreation: false})
    : assert(_sdkRoot != null),
      _trackWidgetCreation = trackWidgetCreation {
    // This is a URI, not a file path, so the forward slash is correct even on Windows.
    if (!_sdkRoot.endsWith('/'))
      _sdkRoot = '$_sdkRoot/';
  }

  final bool _trackWidgetCreation;
  String _sdkRoot;
  Process _server;
  final _StdoutHandler stdoutHandler = new _StdoutHandler();

  /// If invoked for the first time, it compiles Dart script identified by
  /// [mainPath], [invalidatedFiles] list is ignored.
  /// Otherwise, [mainPath] is ignored, but [invalidatedFiles] is recompiled
  /// into new binary.
  /// Binary file name is returned if compilation was successful, otherwise
  /// null is returned.
  Future<String> recompile(String mainPath, List<String> invalidatedFiles,
      {String outputPath}) async {
    stdoutHandler.reset();

    // First time recompile is called we actually have to compile the app from
    // scratch ignoring list of invalidated files.
    if (_server == null)
      return _compile(mainPath, outputPath);

    final String inputKey = new Uuid().generateV4();
    _server.stdin.writeln('recompile $inputKey');
    invalidatedFiles.forEach(_server.stdin.writeln);
    _server.stdin.writeln(inputKey);

    return stdoutHandler.outputFilename.future;
  }

  Future<String> _compile(String scriptFilename, String outputPath) async {
    final String frontendServer = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    final List<String> args = <String>[
      _dartExecutable(),
      frontendServer,
      '--sdk-root',
      _sdkRoot,
      '--incremental',
      '--strong'
    ];
    if (outputPath != null) {
      args.addAll(<String>['--output-dill', outputPath]);
    }
    if (_trackWidgetCreation) {
      args.add('--track-widget-creation');
    }
    _server = await processManager.start(args);
    _server.stdout
      .transform(UTF8.decoder)
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
      .transform(UTF8.decoder)
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
