// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:usage/uuid/uuid.dart';

import 'artifacts.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'globals.dart';

String _dartExecutable() {
  final String engineDartSdkPath = artifacts.getArtifactPath(
    Artifact.engineDartSdkPath
  );
  return fs.path.join(engineDartSdkPath, 'bin', 'dart');
}

Future<String> compile({String sdkRoot, String mainPath}) async {
  final String frontendServer = artifacts.getArtifactPath(
    Artifact.frontendServerSnapshotForEngineDartSdk
  );

  if (!sdkRoot.endsWith('/'))
    sdkRoot = '$sdkRoot/';
  final Process server = await Process.start(_dartExecutable(),
    <String>[frontendServer, '--sdk-root', sdkRoot, mainPath]
  );

  String boundaryKey;
  String outputFilename;
  server.stderr
    .transform(UTF8.decoder)
    .listen((String s) { print(s); });
  server.stdout
    .transform(UTF8.decoder)
    .transform(new LineSplitter())
    .listen((String string) async {
      const String RESULT_PREFIX = 'result ';
      if (boundaryKey == null) {
        if (string.startsWith(RESULT_PREFIX))
          boundaryKey = string.substring(RESULT_PREFIX.length);
      } else {
        if (string.startsWith(boundaryKey)) {
          if (string.length > boundaryKey.length)
            outputFilename = string.substring(boundaryKey.length + 1);
        } else {
          print('compile debug message: $string');
        }
      }
    });
  await server.exitCode;
  return outputFilename;
}

class ResidentCompiler {
  ResidentCompiler(this._sdkRoot) {
    assert(_sdkRoot != null);
    if (!_sdkRoot.endsWith('/'))
      _sdkRoot = '$_sdkRoot/';
  }

  String _sdkRoot;
  Process _server;
  Completer<String> _outputFilename;
  String _boundaryKey;

  Future<String> recompile(String mainPath, List<String> invalidatedFiles) async {
    // First time recompile is called we actually have to compile the app from
    // scratch ignoring list of invalidated files.
    if (_server == null)
      return _compile(mainPath);

    _outputFilename = new Completer<String>();

    final String inputKey = new Uuid().generateV4();
    _server.stdin.writeln('recompile $inputKey');
    for (String invalidatedFile in invalidatedFiles) {
      _server.stdin.writeln(invalidatedFile);
    }
    _server.stdin.writeln(inputKey);

    return _outputFilename.future;
  }

  Future<Null> handler(String string) async {
    const String RESULT_PREFIX = 'result ';
      if (_boundaryKey == null) {
        if (string.startsWith(RESULT_PREFIX)) {
          _boundaryKey = string.substring(RESULT_PREFIX.length);
        }
      } else {
        if (string.startsWith(_boundaryKey)) {
          _outputFilename.complete(string.length > _boundaryKey.length
            ? string.substring(_boundaryKey.length + 1)
            : null
          );
          _boundaryKey = null;
        } else {
          printTrace('compile debug message: $string');
        }
    }
  }

  Future<String> _compile(String scriptFilename) async {
    if (_server == null) {
      final String frontendServer = artifacts.getArtifactPath(
        Artifact.frontendServerSnapshotForEngineDartSdk
      );
      _server = await Process.start(_dartExecutable(),
        <String>[frontendServer, '--sdk-root', _sdkRoot, '--incremental']
      );
    }
    _outputFilename = new Completer<String>();
    _server.stdout
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .listen(handler);
    _server.stderr
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .listen((String s) { printTrace('stderr:>$s'); });

    _server.stdin.writeln('compile $scriptFilename');

    return _outputFilename.future;
  }

  void accept() {
    _server.stdin.writeln('accept');
  }

  void reject() {
    _server.stdin.writeln('reject');
  }
}