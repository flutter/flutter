// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:usage/uuid/uuid.dart';

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
    sdkRoot = "$sdkRoot/";
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
        if (string.startsWith(boundaryKey))
          outputFilename = string.substring(boundaryKey.length + 1);
        else
          print(string);
      }
    });
  await server.exitCode;
  return outputFilename;
}

class ResidentCompiler {
  ResidentCompiler(this._sdkRoot) {
    assert(_sdkRoot != null);
  }

  String _sdkRoot;
  Process _server;
  Completer<String> _outputFilename;
  String _boundaryKey;

  Future<String> recompile(List<String> invalidatedFiles) async {
    if (_server == null) {
      throw new Future<String>.error("Recompile should be preceded by compile");
    }

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
          _outputFilename.complete(string.substring(_boundaryKey.length));
          _boundaryKey = null;
        } else {
          print(string);
        }
    }
  }

  Future<String> compile(String scriptFilename) async {
    if (_server == null) {
      final String frontendServer = artifacts.getArtifactPath(
        Artifact.frontendServerSnapshotForEngineDartSdk
      );
      _server = await Process.start(_dartExecutable(),
        <String>[frontendServer, '--sdk-root', _sdkRoot + '/', '--incremental']
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
      .listen((String s) { print("stderr:>$s"); });

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