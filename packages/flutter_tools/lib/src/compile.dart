// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:usage/uuid/uuid.dart';

import 'artifacts.dart';
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
      printTrace('compile debug message: $string');
  }

  // This is needed to get ready to process next compilation result output,
  // with its own boundary key and new completer.
  void reset() {
    boundaryKey = null;
    outputFilename = new Completer<String>();
  }
}

Future<String> compile({String sdkRoot, String mainPath}) async {
  final String frontendServer = artifacts.getArtifactPath(
    Artifact.frontendServerSnapshotForEngineDartSdk
  );

  // This is a URI, not a file path, so the forward slash is correct even on Windows.
  if (!sdkRoot.endsWith('/'))
    sdkRoot = '$sdkRoot/';
  final Process server = await processManager.start(<String>[
    _dartExecutable(),
    frontendServer,
    '--sdk-root',
    sdkRoot,
    mainPath
  ]).catchError((dynamic error, StackTrace stack) {
    printTrace('Failed to start frontend server $error, $stack');
  });

  final _StdoutHandler stdoutHandler = new _StdoutHandler();

  server.stderr
    .transform(UTF8.decoder)
    .listen((String s) { printTrace('compile debug message: $s'); });
  server.stdout
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(stdoutHandler.handler);
  await server.exitCode;
  return stdoutHandler.outputFilename.future;
}

/// Wrapper around incremental frontend server compiler, that communicates with
/// server via stdin/stdout.
///
/// The wrapper is intended to stay resident in memory as user changes, reloads,
/// restarts the Flutter app.
class ResidentCompiler {
  ResidentCompiler(this._sdkRoot) {
    assert(_sdkRoot != null);
    // This is a URI, not a file path, so the forward slash is correct even on Windows.
    if (!_sdkRoot.endsWith('/'))
      _sdkRoot = '$_sdkRoot/';
  }

  String _sdkRoot;
  Process _server;
  final _StdoutHandler stdoutHandler = new _StdoutHandler();

  /// If invoked for the first time, it compiles Dart script identified by
  /// [mainPath], [invalidatedFiles] list is ignored.
  /// Otherwise, [mainPath] is ignored, but [invalidatedFiles] is recompiled
  /// into new binary.
  /// Binary file name is returned if compilation was successful, otherwise
  /// `null` is returned.
  Future<String> recompile(String mainPath, List<String> invalidatedFiles) async {
    stdoutHandler.reset();

    // First time recompile is called we actually have to compile the app from
    // scratch ignoring list of invalidated files.
    if (_server == null)
      return _compile(mainPath);

    final String inputKey = new Uuid().generateV4();
    _server.stdin.writeln('recompile $inputKey');
    for (String invalidatedFile in invalidatedFiles)
      _server.stdin.writeln(invalidatedFile);
    _server.stdin.writeln(inputKey);

    return stdoutHandler.outputFilename.future;
  }

  Future<String> _compile(String scriptFilename) async {
    final String frontendServer = artifacts.getArtifactPath(
      Artifact.frontendServerSnapshotForEngineDartSdk
    );
    _server = await processManager.start(<String>[
      _dartExecutable(),
      frontendServer,
      '--sdk-root',
      _sdkRoot,
      '--incremental'
    ]);
    _server.stdout
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .listen(stdoutHandler.handler);
    _server.stderr
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .listen((String s) { printTrace('compile debug message: $s'); });

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
}
